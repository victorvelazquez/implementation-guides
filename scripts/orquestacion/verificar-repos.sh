#!/usr/bin/env bash
# Qué queda realmente pendiente de entregar en cada proyecto. Solo lectura.
# Uso:  bash verificar-repos.sh [ruta o prefijo ...]     (sin argumentos, todos los de proyectos.conf)
#
# Regla de trabajo: antes de decir que algo "queda pendiente de commit, subir o fusionar", correr esto;
# nunca deducirlo de la memoria de la conversación. Informa solo entregas reales de la rama actual:
# cambios sin commitear, commits sin subir y stash. Ignora ramas locales viejas ya fusionadas con squash
# (git las ve como "sin subir" aunque no lo estén).
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
seleccionar_proyectos "$@"
for i in "${!PREF[@]}"; do
	d="${RUTA[$i]}"; nombre="${NOMBRE[$i]}"
	es_repo "$d" || { printf '== %-14s no es un repositorio (%s)\n' "$nombre" "$d"; continue; }
	origen=1; tiene_origin "$d" || origen=0
	if [ "$origen" = 1 ]; then
		con_timeout git -C "$d" fetch --quiet 2>/dev/null || echo "   (aviso: no se pudo consultar el remoto de $nombre)"
	fi
	rama="$(git -C "$d" branch --show-current)"
	sucios="$(git -C "$d" status --short | wc -l | tr -d ' ')"
	stashes="$(git -C "$d" stash list | wc -l | tr -d ' ')"
	remoto=""; adelante=0; atras=0
	if [ -n "$rama" ]; then
		remoto="$(git -C "$d" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
		if [ -n "$remoto" ]; then
			adelante="$(git -C "$d" rev-list --count "$remoto..HEAD" 2>/dev/null || echo 0)"
			atras="$(git -C "$d" rev-list --count "HEAD..$remoto" 2>/dev/null || echo 0)"
		fi
	fi
	estado="PENDIENTE"
	if [ "$sucios" = 0 ] && [ "$adelante" = 0 ] && [ "$stashes" = 0 ] && [ "$origen" = 1 ] && [ -n "$rama" ] && [ -n "$remoto" ]; then
		estado="AL DÍA"
	fi
	printf '== %-14s [%s] %s\n' "$nombre" "${rama:-HEAD desacoplado}" "$estado"
	[ "$origen" = 0 ] && echo "   - no tiene remoto 'origin': no se puede comprobar que esté al día"
	[ -z "$rama" ] && echo "   - HEAD desacoplado (no está en ninguna rama)"
	[ "$sucios" != 0 ] && echo "   - $sucios archivo(s) sin commitear"
	[ "$origen" = 1 ] && [ -n "$rama" ] && [ -z "$remoto" ] && echo "   - la rama no tiene upstream"
	[ "$adelante" != 0 ] && echo "   - $adelante commit(s) de esta rama sin subir ($remoto)"
	[ "$atras" != 0 ] && echo "   - el remoto tiene $atras commit(s) nuevo(s) que faltan traer"
	if [ "$stashes" != 0 ]; then
		git -C "$d" stash list | while IFS= read -r l; do l="   - stash: $l"; echo "${l:0:140}"; done
	fi
done
