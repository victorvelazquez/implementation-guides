#!/usr/bin/env bash
# Funciones comunes de los scripts de Orquestación. No se ejecuta solo: lo cargan los demás con
#   source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#
# Lee la lista de proyectos de proyectos.conf (ver proyectos.conf.example); el archivo solo se exige cuando
# hace falta (sin argumentos, o con un prefijo). Una ruta suelta funciona sin él. Variables opcionales:
#   PROYECTOS_CONF   ruta de otro archivo de proyectos
#   RAIZ_PROYECTOS   carpeta contra la que se resuelven las rutas relativas (por defecto, la del script)
#
# Solo lectura sobre los repositorios: no modifica el árbol de trabajo ni el índice (nunca usa "git add");
# `git fetch` sí actualiza las referencias remotas dentro de .git.

export GIT_OPTIONAL_LOCKS=0 GIT_TERMINAL_PROMPT=0
# Para que ${var:0:N} no corte caracteres multibyte.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in *UTF-8*|*utf8*|*UTF8*) ;; *) export LC_CTYPE=C.UTF-8 ;; esac

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${PROYECTOS_CONF:-$AQUI/proyectos.conf}"
BASE="${RAIZ_PROYECTOS:-$AQUI}"
PREF=(); NOMBRE=(); RUTA=(); ROL=()
CPREF=(); CNOMBRE=(); CRUTA=(); CROL=(); CONF_CARGADO=0

limpiar() {
	local v="${1//$'\r'/}"
	v="${v#"${v%%[![:space:]]*}"}"
	v="${v%"${v##*[![:space:]]}"}"
	printf '%s' "$v"
}

# Ejecuta con tope de 30 s si existe `timeout`.
con_timeout() {
	if command -v timeout >/dev/null 2>&1; then timeout 30 "$@"; else "$@"; fi
}

es_repo() { git -C "$1" rev-parse --git-dir >/dev/null 2>&1; }

# Lee proyectos.conf en CPREF/CNOMBRE/CRUTA/CROL. Devuelve 1 si el archivo no existe.
cargar_conf() {
	[ "$CONF_CARGADO" = 1 ] && return 0
	[ -f "$CONF" ] || return 1
	local p r n o d bom=$'\xEF\xBB\xBF'
	while IFS='|' read -r p r n o || [ -n "$p" ]; do
		p="${p#"$bom"}"
		p="$(limpiar "$p")"
		case "$p" in ''|'#'*) continue ;; esac
		r="$(limpiar "$r")"; n="$(limpiar "$n")"; o="$(limpiar "$o")"
		if [[ "$r" == /* || "$r" =~ ^[A-Za-z]:[\/] ]]; then d="$r"; else d="$BASE/$r"; fi
		d="$(cd "$d" 2>/dev/null && pwd || printf '%s' "$d")"
		CPREF+=("$p"); CNOMBRE+=("${n:-$p}"); CRUTA+=("$d"); CROL+=("${o:-proyecto}")
	done < "$CONF"
	CONF_CARGADO=1
	return 0
}

# Carga todos los proyectos del conf (exigido).
cargar_proyectos() {
	cargar_conf || { echo "Falta $CONF: copiá proyectos.conf.example a proyectos.conf y editalo." >&2; exit 2; }
	[ "${#CPREF[@]}" -gt 0 ] || { echo "$CONF no tiene proyectos." >&2; exit 2; }
	PREF=("${CPREF[@]}"); NOMBRE=("${CNOMBRE[@]}"); RUTA=("${CRUTA[@]}"); ROL=("${CROL[@]}")
}

# Sin argumentos: todos los del conf. Con argumentos: cada uno es un prefijo del conf o una ruta suelta.
seleccionar_proyectos() {
	if [ "$#" = 0 ]; then cargar_proyectos; return; fi
	local a i j r
	cargar_conf || true
	for a in "$@"; do
		j=-1
		for i in "${!CPREF[@]}"; do [ "${CPREF[$i]}" = "$a" ] && { j=$i; break; }; done
		if [ "$j" -ge 0 ]; then
			PREF+=("${CPREF[$j]}"); NOMBRE+=("${CNOMBRE[$j]}"); RUTA+=("${CRUTA[$j]}"); ROL+=("${CROL[$j]}")
		else
			if [ -d "$a" ]; then r="$(cd "$a" && pwd)"; else r="$a"; fi
			PREF+=("$a"); NOMBRE+=("$(basename "$a")"); RUTA+=("$r"); ROL+=("proyecto")
		fi
	done
}

# Recibe un prefijo de proyectos.conf o una ruta; imprime la ruta del repositorio.
resolver_repo() {
	local a="$1" i
	cargar_conf || true
	for i in "${!CPREF[@]}"; do
		[ "${CPREF[$i]}" = "$a" ] && { printf '%s' "${CRUTA[$i]}"; return 0; }
	done
	[ -d "$a" ] && { (cd "$a" && pwd); return 0; }
	return 1
}

# ¿Tiene remoto 'origin'?
tiene_origin() { git -C "$1" remote get-url origin >/dev/null 2>&1; }

# Rama base del repositorio: la que apunta origin/HEAD; si no, origin/main, origin/develop u origin/master.
# Sin salida (y código 1) si no se puede determinar.
rama_base() {
	local d="$1" b c
	b="$(git -C "$d" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
	if [ -z "$b" ]; then
		for c in main develop master; do
			if git -C "$d" rev-parse --verify --quiet "refs/remotes/origin/$c" >/dev/null; then b="$c"; break; fi
		done
	fi
	[ -n "$b" ] || return 1
	printf '%s' "$b"
}

# Imprime un motivo por línea si el repositorio NO pasa la puerta. Sin salida = LISTO.
puerta_motivos() {
	local d="$1" base="" rama n atras adelante s origen=0
	if tiene_origin "$d"; then
		origen=1
		con_timeout git -C "$d" fetch --quiet 2>/dev/null || echo "no se pudo consultar el remoto"
	else
		echo "no tiene remoto 'origin': no se puede comprobar que esté al día"
	fi
	rama="$(git -C "$d" branch --show-current)"
	[ -z "$rama" ] && echo "HEAD desacoplado (no está en ninguna rama)"
	if [ "$origen" = 1 ]; then
		if base="$(rama_base "$d")"; then
			[ -n "$rama" ] && [ "$rama" != "$base" ] && echo "está en la rama '$rama' y debería estar en '$base' (volver a la rama base)"
		else
			base=""
			echo "no se pudo determinar la rama base (no hay origin/HEAD, origin/main, origin/develop ni origin/master)"
		fi
	fi
	n="$(git -C "$d" status --short | wc -l | tr -d ' ')"
	[ "$n" != 0 ] && echo "hay $n archivo(s) sin commitear"
	if [ -n "$base" ] && [ "$rama" = "$base" ]; then
		atras="$(git -C "$d" rev-list --count "HEAD..origin/$base" 2>/dev/null || echo 0)"
		[ "$atras" != 0 ] && echo "le faltan $atras commit(s) de origin/$base (actualizar con el remoto)"
		adelante="$(git -C "$d" rev-list --count "origin/$base..HEAD" 2>/dev/null || echo 0)"
		[ "$adelante" != 0 ] && echo "tiene $adelante commit(s) locales de '$base' sin subir"
	fi
	s="$(git -C "$d" stash list | wc -l | tr -d ' ')"
	[ "$s" != 0 ] && echo "hay $s stash(es) guardados (revisar si es trabajo pendiente)"
	return 0
}
