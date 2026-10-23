#!/usr/bin/env bash
# Vista viva del estado de todos los proyectos. Solo lectura sobre los repositorios.
# Uso:  bash estado-vivo.sh [--solo-archivo] [ruta o prefijo ...]
#       (sin rutas, todos los de proyectos.conf; escribe el archivo y lo muestra salvo con --solo-archivo)
#
# Escribe ESTADO-VIVO.md en $ESTADO_DIR (por defecto, ./.estado junto a los scripts). El archivo es una vista
# que se regenera sola: NO se versiona (agregar la carpeta al .gitignore o a .git/info/exclude).
# Los PR abiertos y fusionados se piden a `gh`; si no está instalado, esas columnas quedan vacías.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
SOLO=0; rutas=()
for a in "$@"; do
	if [ "$a" = "--solo-archivo" ]; then SOLO=1; else rutas+=("$a"); fi
done
seleccionar_proyectos "${rutas[@]}"
ESTADO_DIR="${ESTADO_DIR:-$AQUI/.estado}"
mkdir -p "$ESTADO_DIR"
SALIDA="$ESTADO_DIR/ESTADO-VIVO.md"
TMP="$SALIDA.nuevo"
TIENE_GH=0; command -v gh >/dev/null 2>&1 && TIENE_GH=1
pendientes=()
{
	echo "# Estado vivo"
	echo
	echo "Generado: $(date '+%Y-%m-%d %H:%M') (hora local). Se regenera solo; no se edita ni se versiona."
	echo
	echo "| Proyecto | Rama | Cambios sin commitear | Puerta | PR abiertos | Último fusionado |"
	echo "| --- | --- | --- | --- | --- | --- |"
	for i in "${!PREF[@]}"; do
		d="${RUTA[$i]}"; nombre="${NOMBRE[$i]}"
		es_repo "$d" || { echo "| $nombre | — | repositorio no encontrado | — | — | — |"; continue; }
		base="$(rama_base "$d" || true)"
		rama="$(git -C "$d" branch --show-current)"
		sucios="$(git -C "$d" status --short | wc -l | tr -d ' ')"
		# puerta_motivos ya hace el `git fetch`: no se repite acá.
		motivos="$(puerta_motivos "$d" | grep -c . || true)"
		if [ "$motivos" = 0 ]; then puerta="LISTO"; else puerta="NO LISTO"; fi
		abiertos=""; fusionado=""
		if [ "$TIENE_GH" = 1 ]; then
			abiertos="$(cd "$d" && con_timeout gh pr list --state open --json number,title --jq 'map("#\(.number) \(.title | gsub("\\|"; "\\|"))") | join("; ")' 2>/dev/null)"
			fusionado="$(cd "$d" && con_timeout gh pr list --state merged --limit 1 --json number,title,mergedAt --jq 'if length==0 then "" else .[0] | "#\(.number) \(.title | gsub("\\|"; "\\|")) (\((.mergedAt // "")[0:16]))" end' 2>/dev/null)"
		fi
		fila="| $nombre | \`${rama:-HEAD desacoplado}\` | $sucios | $puerta | ${abiertos:-ninguno} | ${fusionado:-—} |"
		echo "${fila:0:420}"
		if [ "$sucios" != 0 ] || [ -z "$rama" ] || { [ -n "$base" ] && [ "$rama" != "$base" ]; }; then
			pendientes+=("$nombre: $sucios archivo(s) sin commitear en \`${rama:-HEAD desacoplado}\`")
		fi
		[ -n "$abiertos" ] && pendientes+=("$nombre: PR abierto esperando fusión: $abiertos")
	done
	echo
	echo "## Pendientes de entrega o fusión (de la persona)"
	echo
	if [ "${#pendientes[@]}" = 0 ]; then echo "Ninguno: todos los repositorios están al día."; else for p in "${pendientes[@]}"; do echo "- $p"; done; fi
} > "$TMP" && mv "$TMP" "$SALIDA"
[ "$SOLO" = 1 ] || cat "$SALIDA"
