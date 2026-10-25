#!/usr/bin/env bash
# Control de adopción: ¿cada proyecto tiene los bloques vigentes y un ROADMAP.md válido? Solo lectura.
# Uso:  bash verificar-adopcion.sh [--remoto] [ruta o prefijo ...]     (sin argumentos, todos los de proyectos.conf)
#   --remoto  valida origin/<base>:docs/ROADMAP.md (REG-7: lo que leen el panel y la sala) en vez del árbol de
#             trabajo. La base sale de origin/HEAD (respaldo main, develop, master). No hace fetch: usa las
#             referencias locales; si hace falta lo último, correr antes `git fetch`. Sin --remoto, avisa si el
#             árbol local difiere del remoto en ese archivo.
# Sale con 1 si algún proyecto tiene errores; los avisos no cambian el código de salida.
#
# Revisa por proyecto:
#   - AGENTS.md: los dos bloques «orquestacion:registro vX.Y» y «orquestacion:ciclo vX.Y» y si coinciden con
#     la versión vigente (archivo VERSION). El marcador anterior «orquestacion:bloque vX.Y» cuenta como los
#     dos juntos, con aviso. Sin ningún bloque ni sección «Orquestación»: proyecto no adoptado (error).
#   - docs/ROADMAP.md: cabecera de tres líneas (en orden, con negritas); tabla con columnas ID, Entrega,
#     Depende de y Estado; IDs bien formados y únicos; Estado reconocible; dependencias que apuntan a IDs
#     de la tabla y sin ciclos. Ausente: error si el proyecto está adoptado, aviso si no.
#   - docs/ORQUESTACION.md: el registro de adopción.
# Además: marcadores de apertura sin cierre (error), marcas <...> sin completar (aviso), fila de tabla tras una
# línea en blanco (aviso), `|` dentro de una celda (error). El bloque Ciclo ausente es solo INFO (recomendado).
# Lectura tolerante: "Completada (PR 44)" se entiende como Completada, pero se avisa que el detalle va en Notas.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
REMOTO=0; ARGS=()
for a in "$@"; do
	case "$a" in
		--remoto) REMOTO=1 ;;
		--*) echo "Opción desconocida: $a" >&2; exit 2 ;;
		*) ARGS+=("$a") ;;
	esac
done
seleccionar_proyectos "${ARGS[@]}"
VIGENTE="$(tr -d '\r\n ' < "$AQUI/VERSION" 2>/dev/null)"; VIGENTE="${VIGENTE:-1.0}"

validar_roadmap() {
	awk '
	function trim(s){ gsub(/\r/,"",s); sub(/^[ \t]+/,"",s); sub(/[ \t]+$/,"",s); return s }
	function limpia(s){ gsub(/[*`]/,"",s); return trim(s) }
	function reconoce(est,   i, s, le) {
		le = tolower(est)
		for (i=1; i<=6; i++) {
			s = tolower(ST[i])
			if (index(le, s) == 1) {
				resto = substr(est, length(ST[i])+1)
				if (resto == "" || resto ~ /^[ ,;:.(-]/) return ST[i]
			}
		}
		return ""
	}
	# Busca ciclos entre IDs de la tabla (recorrido en profundidad); cada ciclo se informa una vez.
	function dfs(u,   vs, nv, k, v, j, camino) {
		estado[u]=1; prof++; pila[prof]=u
		nv=split(adj[u], vs, " ")
		for (k=1; k<=nv; k++) {
			v=vs[k]
			if (estado[v]==1) {
				camino=""
				for (j=1; j<=prof; j++) if (pila[j]==v) break
				for (; j<=prof; j++) camino=camino pila[j] " → "
				print "ERROR\tdependencia circular: " camino v
			} else if (estado[v]!=2) dfs(v)
		}
		estado[u]=2; prof--
	}
	BEGIN {
		ST[1]="Pendiente"; ST[2]="En curso"; ST[3]="Lista"; ST[4]="En revisión"; ST[5]="Completada"; ST[6]="Bloqueada"
		hdr=0; nfilas=0; nd=0; cand=0; nid=0
	}
	# Se lee todo el archivo para poder mirar la línea siguiente.
	function es_sep(s) { gsub(/\r/,"",s); return (s ~ /^[ \t]*\|[ \t:|-]*$/ && s ~ /-/) }
	{ L[NR]=$0 }
	END { for (k=1; k<=NR; k++) procesa(k); final() }
	function procesa(i,   linea, n, c, j, h, id, est, dep, p, ini) {
		linea=L[i]; gsub(/\r/,"",linea)
		if (linea !~ /^[ \t]*\|/) { if (hdr && entabla) fin=1; bloque=0; return }
		if (fin) {
			# Después de terminada la tabla: una tabla nueva (cabecera + separador) se ignora en silencio;
			# unas filas sueltas (p. ej. tras una línea en blanco) se avisan una vez por bloque.
			if (bloque) return
			bloque=1
			if (es_sep(L[i+1])) return
			print "AVISO\tlínea " i ": fila de tabla después de una línea en blanco: Markdown la separa de la tabla de unidades; quitá la línea en blanco"
			return
		}
		n=split(linea, c, "|")
		if (trim(c[n]) == "") n--      # la última celda vacía es la barra final; si falta, la celda es real
		if (!hdr) {
			split("", col)
			for (j=2; j<=n; j++) { h=tolower(limpia(c[j])); col[h]=j }
			if (("id" in col) || ("estado" in col)) {
				cand=1; miss=""
				if (!("id" in col)) miss=miss " ID"
				if (!("entrega" in col)) miss=miss " Entrega"
				if (!("depende de" in col)) miss=miss " «Depende de»"
				if (!("estado" in col)) miss=miss " Estado"
				if (miss == "") { hdr=1; return } else { candmiss=miss }
			}
			return
		}
		if (es_sep(linea)) { entabla=1; return }
		if (index(linea, "\\|")) {
			nfilas++
			print "ERROR\tlínea " i ": hay un `\\|` dentro de una celda; no uses | en el contenido de la tabla (ni escapado), cambiá el texto"
			return
		}
		id=limpia(c[col["id"]]); est=limpia(c[col["estado"]]); dep=limpia(c[col["depende de"]])
		if (id == "") return
		nfilas++
		if (id in vistos) print "ERROR\tlínea " i ": ID repetido: " id
		else { nid++; orden[nid]=id }
		vistos[id]=1
		if (id !~ /^[A-Za-z][A-Za-z0-9._-]*$/) print "ERROR\tlínea " i ": ID mal formado: «" id "» (letras, números, punto, guion y guion bajo; empieza con letra)"
		p=reconoce(est)
		if (p == "") print "ERROR\tlínea " i ": Estado no reconocido en " id ": «" est "»"
		else {
			ini=substr(est, 1, length(p))
			if (ini != p) print "AVISO\tlínea " i ": Estado en " id ": «" ini "», usar «" p "»"
			if (resto != "") print "AVISO\tlínea " i ": Estado con detalle en " id ": «" est "» (dejar solo «" p "» y el detalle en Notas)"
			if (p == "Lista" || p == "En revisión") print "AVISO\tlínea " i ": Estado «" p "» escrito a mano en " id ": se calcula desde Git, no se escribe"
		}
		nd++; dl[nd]=i; di[nd]=id; dd[nd]=dep
	}
	function final(   k, m, j, t, partes) {
		if (!hdr) {
			if (cand) print "ERROR\tfalta una columna obligatoria:" candmiss
			else print "ERROR\tno se encontró la tabla de unidades"
			exit
		}
		if (nfilas == 0) print "AVISO\tla tabla no tiene filas"
		for (k=1; k<=nd; k++) {
			m=split(dd[k], partes, /[,;]/)
			for (j=1; j<=m; j++) {
				t=trim(partes[j]); sub(/[ \t].*$/, "", t)
				if (t == "" || t == "—" || t == "-") continue
				if (t in vistos) { if (index(" " adj[di[k]], " " t " ") == 0) adj[di[k]]=adj[di[k]] " " t; continue }
				if (t ~ /^[A-Za-z][A-Za-z0-9]*-[A-Za-z0-9._-]+$/) continue
				if (t ~ /^[A-Za-z]+[0-9][A-Za-z0-9._]*$/) {
					ult=""
					for (q=1; q<=nid; q++) if (orden[q] ~ /^[A-Za-z]/ && index(orden[q], t) == 1 && substr(orden[q], length(t)+1) ~ /^[A-Za-z]+$/) ult=orden[q]
					if (ult != "") print "AVISO	línea " dl[k] ": " di[k] " depende de «" t "», que no existe en la tabla: ¿grupo? usá la última fila, p. ej. " ult
					else print "AVISO	línea " dl[k] ": " di[k] " depende de «" t "», que no existe en la tabla (¿error de tipeo o externa?)"
				}
			}
		}
		for (k=1; k<=nid; k++) if (estado[orden[k]]==0) dfs(orden[k])
	}'
}

errores_total=0; avisos_total=0
err() { echo "   ERROR: $1"; errores_total=$((errores_total+1)); }
avi() { echo "   AVISO: $1"; avisos_total=$((avisos_total+1)); }

# Contenido de un archivo sin el BOM UTF-8 inicial (los números de línea no cambian).
sin_bom() { sed '1s/^\xEF\xBB\xBF//' "$1"; }

# Informa un bloque ($1 nombre, $2 versión o vacío).
informar_bloque() {
	if [ -z "$2" ]; then
		if [ "$1" = Ciclo ]; then echo "   INFO: bloque Ciclo no adoptado (recomendado, no obligatorio en el perfil «proyecto independiente»)"
		else avi "AGENTS.md no tiene el bloque $1 (ausente)"; fi
	elif [ "$2" = "$VIGENTE" ]; then echo "   AGENTS.md: bloque $1 v$2 (vigente)"
	else avi "AGENTS.md tiene el bloque $1 v$2 y la versión vigente es v$VIGENTE (desactualizado)"; fi
}

# Todo marcador de apertura necesita su cierre ($1 texto de AGENTS.md, $2 registro o ciclo).
revisar_cierre() {
	if printf '%s\n' "$1" | grep -q "orquestacion:$2 v[0-9]" && ! printf '%s\n' "$1" | grep -q "<!-- /orquestacion:$2 -->"; then
		err "AGENTS.md: marcador sin cierre: falta <!-- /orquestacion:$2 -->"
	fi
}

for i in "${!PREF[@]}"; do
	d="${RUTA[$i]}"; nombre="${NOMBRE[$i]}"; rol="${ROL[$i]}"
	echo "== $nombre"
	[ -d "$d" ] || { err "la carpeta no existe ($d)"; continue; }
	if [ "$rol" = "sala" ]; then
		echo "   sala de Dirección: revisar a mano AGENTS.md (plantilla AGENTS-sala), TABLERO.md y ENLACES.md"
		continue
	fi
	# 1. Bloques en AGENTS.md
	adoptado=0
	if [ ! -f "$d/AGENTS.md" ]; then
		otro=""
		for f in CLAUDE.md GEMINI.md .cursorrules .github/copilot-instructions.md; do
			[ -f "$d/$f" ] && { otro="$f"; break; }
		done
		if [ -z "$otro" ]; then
			err "no existe AGENTS.md"
		elif grep -q 'orquestacion:\|Orquestación' "$d/$otro"; then
			adoptado=1
			avi "no existe AGENTS.md (hay $otro, que tiene un bloque de Orquestación; si ese es el archivo de instrucciones del agente, el bloque va ahí)"
		else
			err "no existe AGENTS.md (hay $otro; si ese es el archivo de instrucciones del agente, el bloque va ahí)"
		fi
	else
		ag="$(sin_bom "$d/AGENTS.md")"
		vreg="$(printf '%s\n' "$ag" | grep -o 'orquestacion:registro v[0-9][0-9.]*' | head -1)"; vreg="${vreg##*v}"
		vcic="$(printf '%s\n' "$ag" | grep -o 'orquestacion:ciclo v[0-9][0-9.]*' | head -1)"; vcic="${vcic##*v}"
		vant="$(printf '%s\n' "$ag" | grep -o 'orquestacion:bloque v[0-9][0-9.]*' | head -1)"; vant="${vant##*v}"
		if [ -n "$vreg" ] || [ -n "$vcic" ] || [ -n "$vant" ]; then
			adoptado=1
			if [ -n "$vant" ]; then
				avi "AGENTS.md tiene el marcador anterior «orquestacion:bloque v$vant»; pasar a los dos bloques (registro y ciclo)"
				[ "$vant" = "$VIGENTE" ] || avi "el marcador anterior es v$vant y la versión vigente es v$VIGENTE"
				[ -n "$vreg" ] && informar_bloque Registro "$vreg"
				[ -n "$vcic" ] && informar_bloque Ciclo "$vcic"
			else
				informar_bloque Registro "$vreg"
				informar_bloque Ciclo "$vcic"
				[ -n "$vcic" ] && [ -z "$vreg" ] && avi "AGENTS.md tiene el bloque Ciclo sin el bloque Registro"
			fi
			revisar_cierre "$ag" registro
			revisar_cierre "$ag" ciclo
		elif printf '%s\n' "$ag" | grep -q 'Orquestación'; then
			adoptado=1
			avi "AGENTS.md tiene una sección de Orquestación sin marcadores de versión (anterior a la v$VIGENTE)"
		else
			err "AGENTS.md no tiene el bloque de Orquestación (proyecto no adoptado)"
		fi
	fi
	# 2. ROADMAP.md (del árbol de trabajo; con --remoto, de origin/<base> según las referencias locales)
	rm_="$d/docs/ROADMAP.md"
	rem_ok=0; rem_msg=""; rem_base=""; rem_texto=""
	if [ -n "$(git -C "$d" rev-parse --show-prefix 2>/dev/null)" ] || ! es_repo "$d"; then rem_msg="no es la raíz de un repositorio Git"
	elif ! tiene_origin "$d"; then rem_msg="no tiene remoto 'origin'"
	elif ! rem_base="$(rama_base "$d")" || ! git -C "$d" rev-parse --verify --quiet "refs/remotes/origin/$rem_base" >/dev/null; then
		rem_msg="origin/${rem_base:-<base>} no existe en las referencias locales (git fetch; este control no lo hace solo)"; rem_base=""
	elif rem_texto="$(git -C "$d" show "origin/$rem_base:docs/ROADMAP.md" 2>/dev/null)"; then rem_ok=1
	else rem_msg="no existe docs/ROADMAP.md en origin/$rem_base"; fi
	texto=""; hay=0; etiqueta="docs/ROADMAP.md"
	if [ "$REMOTO" = 1 ]; then
		if [ "$rem_ok" = 1 ]; then
			hay=1; texto="$(printf '%s\n' "$rem_texto" | sed '1s/^\xEF\xBB\xBF//')"; etiqueta="origin/$rem_base:docs/ROADMAP.md"
		elif [ "$adoptado" = 1 ]; then err "--remoto: $rem_msg"
		else avi "--remoto: $rem_msg"; fi
	elif [ ! -f "$rm_" ]; then
		if [ "$adoptado" = 1 ]; then err "no existe docs/ROADMAP.md (el proyecto está adoptado)"; else avi "no existe docs/ROADMAP.md"; fi
	else
		hay=1; texto="$(sin_bom "$rm_")"
		# REG-7: los lectores (panel, sala) leen origin/<base>; si el árbol local no coincide, lo que ven es otra cosa.
		if [ "$rem_ok" = 1 ]; then
			rem_cmp="$(printf '%s\n' "$rem_texto" | sed '1s/^\xEF\xBB\xBF//')"
			[ "${texto//$'\r'/}" = "${rem_cmp//$'\r'/}" ] || avi "docs/ROADMAP.md local difiere de origin/$rem_base: los lectores (panel, sala) leen el remoto; validarlo con --remoto"
		elif [ "$rem_base" != "" ]; then
			avi "docs/ROADMAP.md existe en el árbol local pero no en origin/$rem_base (adopción sin entregar): los lectores (panel, sala) no lo ven"
		fi
	fi
	if [ "$hay" = 1 ]; then
		e0=$errores_total; a0=$avisos_total
		# La cabecera es obligatoria (REG-2): error si el proyecto está adoptado, aviso si no.
		if [ "$adoptado" = 1 ]; then cab_falla() { err "$1"; }; else cab_falla() { avi "$1"; }; fi
		falta=0
		l1="$(printf '%s\n' "$texto" | grep -n -m1 '^\*\*Dónde está:\*\*' | cut -d: -f1)"
		l2="$(printf '%s\n' "$texto" | grep -n -m1 '^\*\*Qué sigue:\*\*' | cut -d: -f1)"
		l3="$(printf '%s\n' "$texto" | grep -n -m1 '^\*\*Qué lo bloquea:\*\*' | cut -d: -f1)"
		[ -n "$l1" ] || { cab_falla "ROADMAP.md sin la línea «**Dónde está:**» al inicio de línea (cabecera)"; falta=1; }
		[ -n "$l2" ] || { cab_falla "ROADMAP.md sin la línea «**Qué sigue:**» al inicio de línea (cabecera)"; falta=1; }
		[ -n "$l3" ] || { cab_falla "ROADMAP.md sin la línea «**Qué lo bloquea:**» al inicio de línea (cabecera)"; falta=1; }
		if [ "$falta" = 0 ] && ! { [ "$l1" -lt "$l2" ] && [ "$l2" -lt "$l3" ]; }; then
			cab_falla "ROADMAP.md: la cabecera debe ir en el orden «Dónde está», «Qué sigue», «Qué lo bloquea»"
		fi
		# Marcas <...> de la plantilla sin completar (en la cabecera o en la tabla); <br> no cuenta.
		if printf '%s\n' "$texto" | sed 's/<br *\/\?>//g' | grep -Eq '^(\*\*(Dónde está|Qué sigue|Qué lo bloquea):\*\*|[[:space:]]*\|).*<[^>]+>'; then
			avi "ROADMAP.md tiene marcas <...> sin completar"
		fi
		hallazgos="$(printf '%s\n' "$texto" | validar_roadmap)"
		while IFS=$'\t' read -r tipo msg; do
			[ -z "$tipo" ] && continue
			if [ "$tipo" = "ERROR" ]; then err "ROADMAP.md, $msg"; else avi "ROADMAP.md, $msg"; fi
		done <<< "$hallazgos"
		[ "$errores_total" = "$e0" ] && [ "$avisos_total" = "$a0" ] && echo "   $etiqueta: válido"
	fi
	# 3. Registro de adopción
	if [ -f "$d/docs/ORQUESTACION.md" ]; then echo "   docs/ORQUESTACION.md: presente"; else avi "falta docs/ORQUESTACION.md (registro de adopción)"; fi
done
echo
echo "Resumen: $errores_total error(es), $avisos_total aviso(s). Versión vigente de los bloques: v$VIGENTE."
[ "$errores_total" = 0 ]
