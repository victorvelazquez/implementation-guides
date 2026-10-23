# Limpieza del registro de sesiones

**Solo si usás Gentle Shell (Pi) en Windows.** Lee la carpeta `%USERPROFILE%\.gentle-shell\agent\gentle-agents`. Con otro agente hay que adaptar qué significa «sesión viva».

## Para qué

Gentle Shell no elimina el registro de una sesión que se cierra mal. El registro del ayudante tiene un tope de 64 entradas y el directorio de presencia escanea como máximo 128 por página. Al superarlos, la herramienta de mensajería entre sesiones falla con «session discovery is unavailable» y la sala deja de poder ordenar a los proyectos.

## Qué hace

- Considera **viva** una sesión si su registro está bloqueado por un proceso, o si su tubería existe en `\\.\pipe\`. **No usa la fecha de modificación** (no es confiable: puede haber sesiones vivas con archivos de días).
- **Mueve** (no borra) lo muerto y de más de una hora a `gentle-agents\transport\respaldo\<fecha>` y `gentle-agents\respaldo\<fecha>`.
- Purga los respaldos de más de 14 días.
- Si no puede listar las tuberías o no encuentra las carpetas, **aborta sin tocar nada**.
- Deja un registro en `limpieza.log` (se recorta a 200 KB).

## Uso

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File limpiar-sesiones.ps1 -Simular   # muestra qué movería, sin mover
powershell -NoProfile -ExecutionPolicy Bypass -File limpiar-sesiones.ps1             # ejecuta
```

Parámetros: `-HorasMinimas` (1) y `-DiasRespaldo` (14).

## Programarla (una vez al día)

```powershell
schtasks /Create /TN "Orquestacion\LimpiarSesiones" /SC DAILY /ST 12:30 /F `
  /TR "powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"<ruta>\limpiar-sesiones.ps1\""
```

Para que corra también con batería y recupere una ejecución perdida porque la PC estaba apagada, hay que cambiar tres ajustes de la tarea: exportarla con `schtasks /Query /TN ... /XML`, poner `DisallowStartIfOnBatteries=false`, `StopIfGoingOnBatteries=false` y `StartWhenAvailable=true`, y reimportarla con `/Create /XML`. El archivo XML debe estar en **UTF-16**. Crear un disparador «al iniciar sesión» exige permisos de administrador.

## Restaurar

Si algo se movió por error, copiar el archivo desde `respaldo\<fecha>` a `presence` o a `transport\presence`.

## Probar que anda

Con la mensajería rota por acumulación: correr con `-Simular`, revisar cuántos registros movería, correr de verdad y volver a listar sesiones. Con el registro sano, debe informar «mover=0».

## Límite conocido

Si Gentle Shell cambia el formato de sus registros (nombres de archivo o el campo `endpoint`), el script puede dejar de reconocer sesiones vivas. Lo que mueve siempre se puede recuperar del respaldo durante 14 días. Un registro ilegible, sin bloqueo ni tubería y de más de una hora, **sí** se considera muerto: ese es el caso a revisar si algo falla.
