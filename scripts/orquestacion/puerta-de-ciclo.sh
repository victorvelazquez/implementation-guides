#!/usr/bin/env bash
# Puerta de arranque de ciclo. No modifica el árbol de trabajo ni el índice; `git fetch` sí actualiza las
# referencias remotas dentro de .git.
# Uso:  bash puerta-de-ciclo.sh <prefijo | ruta>
# Sale con 0 y dice LISTO, o sale con 1 y dice NO LISTO con los motivos.
# Una ruta suelta funciona sin proyectos.conf; el prefijo lo necesita.
#
# Regla CIC-1: antes de arrancar una unidad nueva, el repositorio está en la rama base, limpio, al día con
# el remoto y sin stash. La sala la corre antes de dar cualquier orden de cambio o `siguiente`; la sesión
# del proyecto la repite por su cuenta. Ver el PR fusionado en el alojamiento no alcanza.
# Solo aplica a ARRANCAR una unidad, no a seguir una en curso ni a corregir un PR abierto.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
arg="${1:?uso: puerta-de-ciclo.sh <prefijo | ruta>}"
repo="$(resolver_repo "$arg")" || { echo "NO LISTO: '$arg' no es una carpeta ni figura en proyectos.conf"; exit 1; }
es_repo "$repo" || { echo "NO LISTO: $repo no es un repositorio"; exit 1; }
nombre="$(basename "$repo")"
motivos=()
while IFS= read -r m; do [ -n "$m" ] && motivos+=("$m"); done < <(puerta_motivos "$repo")
if [ "${#motivos[@]}" = 0 ]; then
	echo "LISTO: $nombre está en '$(rama_base "$repo")', limpio y al día con el remoto."
	exit 0
fi
echo "NO LISTO: $nombre"
for m in "${motivos[@]}"; do echo "   - $m"; done
exit 1
