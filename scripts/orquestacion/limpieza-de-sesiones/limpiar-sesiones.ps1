# limpiar-sesiones.ps1
# Limpia los registros de sesiones muertas de Gentle Shell (carpeta gentle-agents).
#
# Por que existe: Gentle Shell no elimina el registro de una sesion que se cierra mal.
# El registro del helper tiene un tope de 64 entradas y el directorio de presencia escanea
# como maximo 128 por pagina. Al superarlos, orchestrator_list falla con
# "session discovery is unavailable".
#
# Criterio de "viva" (NO se usa la fecha de modificacion, no es confiable):
#   1. El registro esta bloqueado por un proceso (Windows no deja leerlo), o
#   2. Su tuberia (endpoint) existe en \\.\pipe\.
# Solo se mueve lo que no esta vivo Y es mas viejo que -HorasMinimas (evita sesiones que
# estan arrancando). Nunca borra de primera: mueve a un respaldo y purga el respaldo
# despues de -DiasRespaldo.
#
# Uso:
#   .\limpiar-sesiones.ps1 -Simular     # muestra que se movera, sin mover nada
#   .\limpiar-sesiones.ps1              # ejecuta
param(
	[switch]$Simular,
	[int]$HorasMinimas = 1,
	[int]$DiasRespaldo = 14
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$agentes = Join-Path $env:USERPROFILE '.gentle-shell\agent\gentle-agents'
$registro = Join-Path $agentes 'transport\presence'
$presencia = Join-Path $agentes 'presence'
$sello = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$respaldoRegistro = Join-Path $agentes ('transport\respaldo\' + $sello)
$respaldoPresencia = Join-Path $agentes ('respaldo\' + $sello)
$logPath = Join-Path $PSScriptRoot 'limpieza.log'
$limite = (Get-Date).AddHours(-$HorasMinimas)

function Escribir([string]$texto) {
	$linea = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $texto
	Write-Output $linea
	try { Add-Content -LiteralPath $logPath -Value $linea -Encoding ASCII } catch { }
}

# Mantiene el log acotado.
if ((Test-Path -LiteralPath $logPath) -and ((Get-Item -LiteralPath $logPath).Length -gt 200KB)) {
	Remove-Item -LiteralPath $logPath -Force
}

if (-not (Test-Path -LiteralPath $registro) -or -not (Test-Path -LiteralPath $presencia)) {
	Escribir 'ABORTA: no existen las carpetas de Gentle Shell esperadas. No se toco nada.'
	exit 2
}

# Tuberias activas del sistema.
$barra = [string][char]92
$raizPipe = $barra + $barra + '.' + $barra + 'pipe' + $barra
try {
	$tuberias = @([IO.Directory]::GetFiles($raizPipe) | ForEach-Object { Split-Path $_ -Leaf })
} catch {
	Escribir 'ABORTA: no se pudo listar las tuberias. No se toco nada.'
	exit 3
}

$sha = [Security.Cryptography.SHA256]::Create()
function HashDeSesion([string]$id) {
	(($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($id)) | ForEach-Object { $_.ToString('x2') }) -join '')
}

$vivasIds = New-Object 'System.Collections.Generic.HashSet[string]'
$muertosRegistro = New-Object System.Collections.ArrayList
$conservadosRegistro = 0

foreach ($archivo in Get-ChildItem -LiteralPath $registro -File) {
	$idSesion = $archivo.Name.Split('.')[0]
	$bloqueado = $false
	$hoja = $null
	try {
		$flujo = [IO.File]::Open($archivo.FullName, 'Open', 'Read', 'Read')
		try {
			$lector = New-Object IO.StreamReader($flujo)
			$json = $lector.ReadToEnd() | ConvertFrom-Json
			if ($json.PSObject.Properties['endpoint']) { $hoja = Split-Path ([string]$json.endpoint) -Leaf }
		} finally { $flujo.Dispose() }
	} catch [System.IO.IOException] {
		$bloqueado = $true
	} catch {
		$hoja = $null
	}
	$tuberiaViva = ($null -ne $hoja) -and ($tuberias -contains $hoja)
	if ($bloqueado -or $tuberiaViva) {
		[void]$vivasIds.Add($idSesion)
		$conservadosRegistro++
	} elseif ($archivo.LastWriteTime -lt $limite) {
		[void]$muertosRegistro.Add($archivo)
	} else {
		$conservadosRegistro++
	}
}

# Archivos de presencia: <hashDeSesion>.<uuid>.<tipo>.json. Se conservan los de sesiones vivas.
$hashesVivos = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($id in $vivasIds) { [void]$hashesVivos.Add((HashDeSesion $id)) }
$muertosPresencia = New-Object System.Collections.ArrayList
$conservadosPresencia = 0
foreach ($archivo in Get-ChildItem -LiteralPath $presencia -File) {
	$hash = $archivo.Name.Split('.')[0]
	if ($hashesVivos.Contains($hash)) { $conservadosPresencia++ }
	elseif ($archivo.LastWriteTime -lt $limite) { [void]$muertosPresencia.Add($archivo) }
	else { $conservadosPresencia++ }
}

$modo = if ($Simular) { 'SIMULACION' } else { 'EJECUCION' }
Escribir ('{0}: sesiones vivas={1}; registro: mover={2} conservar={3}; presencia: mover={4} conservar={5}' -f $modo, $vivasIds.Count, $muertosRegistro.Count, $conservadosRegistro, $muertosPresencia.Count, $conservadosPresencia)

if (-not $Simular) {
	$fallos = 0
	if ($muertosRegistro.Count -gt 0) {
		New-Item -ItemType Directory -Force -Path $respaldoRegistro | Out-Null
		foreach ($f in $muertosRegistro) {
			try { Move-Item -LiteralPath $f.FullName -Destination $respaldoRegistro -ErrorAction Stop } catch { $fallos++ }
		}
	}
	if ($muertosPresencia.Count -gt 0) {
		New-Item -ItemType Directory -Force -Path $respaldoPresencia | Out-Null
		foreach ($f in $muertosPresencia) {
			try { Move-Item -LiteralPath $f.FullName -Destination $respaldoPresencia -ErrorAction Stop } catch { $fallos++ }
		}
	}
	if ($fallos -gt 0) { Escribir ('Aviso: {0} archivos no se pudieron mover (probablemente se volvieron a usar). Se dejaron en su lugar.' -f $fallos) }

	# Purga de respaldos con mas de -DiasRespaldo (solo las carpetas con sello de este script).
	$corte = (Get-Date).AddDays(-$DiasRespaldo)
	$raicesRespaldo = @((Join-Path $agentes 'transport\respaldo'), (Join-Path $agentes 'respaldo'))
	$purgadas = 0
	foreach ($raiz in $raicesRespaldo) {
		if (-not (Test-Path -LiteralPath $raiz)) { continue }
		foreach ($carpeta in Get-ChildItem -LiteralPath $raiz -Directory) {
			if ($carpeta.Name -match '^\d{4}-\d{2}-\d{2}_\d{6}$' -and $carpeta.LastWriteTime -lt $corte) {
				Remove-Item -LiteralPath $carpeta.FullName -Recurse -Force
				$purgadas++
			}
		}
	}
	if ($purgadas -gt 0) { Escribir ('Respaldos purgados (mas de {0} dias): {1}' -f $DiasRespaldo, $purgadas) }
}
exit 0
