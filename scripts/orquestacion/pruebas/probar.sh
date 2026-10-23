#!/usr/bin/env bash
# Pruebas de regresión de los scripts de Orquestación.
# Uso:  bash pruebas/probar.sh        (desde la carpeta scripts/orquestacion o desde cualquier otra)
# Crea repositorios y proyectos temporales SOLO en scripts/orquestacion/.tmp-pruebas/, los borra al terminar
# y sale con código distinto de 0 si algún caso falla. No toca ningún repositorio real.
SCR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$SCR/.tmp-pruebas"
rm -rf "$S"
mkdir -p "$S/remotos" "$S/p" "$S/bin"
limpiar_todo() { rm -rf "$S"; rmdir "$S" 2>/dev/null; [ -e "$S" ] && echo "AVISO: no se pudo borrar $S; borralo a mano." >&2; return 0; }
trap limpiar_todo EXIT

# Git aislado de la configuración del usuario.
printf '[user]\n\tname = Prueba\n\temail = prueba@example.com\n[commit]\n\tgpgsign = false\n[init]\n\tdefaultBranch = main\n' > "$S/gitconfig"
export GIT_CONFIG_GLOBAL="$S/gitconfig" GIT_CONFIG_NOSYSTEM=1
export PROYECTOS_CONF="$S/no-existe.conf"
unset RAIZ_PROYECTOS ESTADO_DIR

OKS=0; FALLAS=0; OUT=""; RC=0; DETALLE=""; NOMBRE_CASO=""; MALO=0

caso() { NOMBRE_CASO="$1"; MALO=0; DETALLE=""; }
corre() { OUT="$("$@" 2>&1)"; RC=$?; }
rc_es() { [ "$RC" = "$1" ] || { DETALLE="$DETALLE
     esperaba código $1 y fue $RC"; MALO=1; }; }
tiene() { case "$OUT" in *"$1"*) ;; *) DETALLE="$DETALLE
     falta en la salida: $1"; MALO=1 ;; esac; }
no_tiene() { case "$OUT" in *"$1"*) DETALLE="$DETALLE
     sobra en la salida: $1"; MALO=1 ;; esac; }
cuenta_es() { local n; n="$(printf '%s\n' "$OUT" | grep -c -- "$1")"; [ "$n" = "$2" ] || { DETALLE="$DETALLE
     esperaba $2 línea(s) con «$1» y hubo $n"; MALO=1; }; }
fin() {
	if [ "$MALO" = 0 ]; then echo "OK     $NOMBRE_CASO"; OKS=$((OKS+1))
	else echo "FALLA  $NOMBRE_CASO"; echo "$DETALLE"; printf '%s\n' "$OUT" | sed 's/^/     | /'; FALLAS=$((FALLAS+1)); fi
}

# --- fixtures de Git ---------------------------------------------------------------------------------
# repo_nuevo <nombre> [rama base]: remoto bare + clon con un commit, subido con upstream.
repo_nuevo() {
	local n="$1" b="${2:-main}"
	git init -q --bare -b "$b" "$S/remotos/$n.git"
	git init -q -b "$b" "$S/$n"
	git -C "$S/$n" commit -q --allow-empty -m inicial
	git -C "$S/$n" remote add origin "$S/remotos/$n.git"
	git -C "$S/$n" push -q -u origin "$b" 2>/dev/null
}
puerta() { corre bash "$SCR/puerta-de-ciclo.sh" "$@"; }
repos() { corre bash "$SCR/verificar-repos.sh" "$@"; }
adopcion() { corre timeout 20 bash "$SCR/verificar-adopcion.sh" "$@"; }

# --- fixtures de adopción ----------------------------------------------------------------------------
cab() { printf '# Hoja de ruta\n\n**Dónde está:** x.\n**Qué sigue:** y.\n**Qué lo bloquea:** nada.\n\n'; }
# proyecto_adoptado <nombre>: AGENTS.md con los dos bloques vigentes, registro y un ROADMAP válido.
proyecto_adoptado() {
	local p="$S/p/$1"
	mkdir -p "$p/docs"
	printf '# AGENTS\n<!-- orquestacion:registro v1.0 -->\nr\n<!-- /orquestacion:registro -->\n<!-- orquestacion:ciclo v1.0 -->\nc\n<!-- /orquestacion:ciclo -->\n' > "$p/AGENTS.md"
	printf '# Registro\n' > "$p/docs/ORQUESTACION.md"
	roadmap "$1" <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | Adoptar | — | Completada |
| U1 | Algo | U0 | Pendiente |
EOF
}
roadmap() { { cab; cat; } > "$S/p/$1/docs/ROADMAP.md"; }
ruta_p() { printf '%s' "$S/p/$1"; }

# =====================================================================================================
caso "01 ruta suelta sin proyectos.conf (puerta, repos y adopción)"
repo_nuevo r01
puerta "$S/r01"; rc_es 0; tiene "LISTO: r01 está en 'main'"; no_tiene "Falta"
if [ "$MALO" = 0 ]; then repos "$S/r01"; rc_es 0; tiene "AL DÍA"; no_tiene "Falta"; fi
if [ "$MALO" = 0 ]; then proyecto_adoptado a01; adopcion "$(ruta_p a01)"; rc_es 0; no_tiene "Falta"; fi
fin

caso "02 proyectos.conf con BOM (comentario con BOM no crea proyecto fantasma)"
repo_nuevo r02
{ printf '\xEF\xBB\xBF# comentario con BOM\n'; printf 'rr|%s|Repo R|proyecto\n' "$S/r02"; } > "$S/bom.conf"
PROYECTOS_CONF="$S/bom.conf" repos; OUT="$(PROYECTOS_CONF="$S/bom.conf" bash "$SCR/verificar-repos.sh" 2>&1)"; RC=$?
rc_es 0; tiene "== Repo R"; cuenta_es '^==' 1
printf '\xEF\xBB\xBFrr|%s|Repo R|proyecto\n' "$S/r02" > "$S/bom2.conf"
OUT="$(PROYECTOS_CONF="$S/bom2.conf" bash "$SCR/puerta-de-ciclo.sh" rr 2>&1)"; RC=$?
rc_es 0; tiene "LISTO: r02"
fin

caso "03 proyectos.conf con CRLF"
repo_nuevo r03
printf '# lista\r\nrr|%s|Repo R|proyecto\r\n' "$S/r03" > "$S/crlf.conf"
OUT="$(PROYECTOS_CONF="$S/crlf.conf" bash "$SCR/verificar-repos.sh" 2>&1)"; RC=$?
rc_es 0; tiene "== Repo R"; no_tiene "no es un repositorio"; tiene "AL DÍA"
OUT="$(PROYECTOS_CONF="$S/crlf.conf" bash "$SCR/puerta-de-ciclo.sh" rr 2>&1)"; RC=$?
rc_es 0; tiene "LISTO: r03"
fin

caso "04 worktree (.git es un archivo)"
repo_nuevo r04
git -C "$S/r04" worktree add -q -b rama-wt "$S/wt04" 2>/dev/null
puerta "$S/wt04"; rc_es 1; no_tiene "no es un repositorio"; tiene "está en la rama 'rama-wt'"
repos "$S/wt04"; no_tiene "no es un repositorio"; tiene "[rama-wt]"
fin

caso "05 repo sin remoto"
mkdir -p "$S/r05"; git init -q -b main "$S/r05"; git -C "$S/r05" commit -q --allow-empty -m i
puerta "$S/r05"; rc_es 1; cuenta_es "^LISTO:" 0; tiene "no tiene remoto 'origin': no se puede comprobar que esté al día"
repos "$S/r05"; tiene "no tiene remoto 'origin': no se puede comprobar que esté al día"; no_tiene "?"; no_tiene "AL DÍA"
fin

caso "06 HEAD desacoplado"
repo_nuevo r06
git -C "$S/r06" checkout -q --detach
puerta "$S/r06"; rc_es 1; tiene "HEAD desacoplado (no está en ninguna rama)"
repos "$S/r06"; tiene "[HEAD desacoplado]"; no_tiene "AL DÍA"
fin

caso "07 rama base master (sin origin/HEAD)"
repo_nuevo r07 master
puerta "$S/r07"; rc_es 0; tiene "LISTO: r07 está en 'master'"
fin

caso "07b sin rama base reconocible"
repo_nuevo r07b trunk
# git reciente crea origin/HEAD en cada fetch; se lo desactiva para simular un remoto sin HEAD.
git -C "$S/r07b" config remote.origin.followRemoteHEAD never
git -C "$S/r07b" symbolic-ref --delete refs/remotes/origin/HEAD 2>/dev/null
puerta "$S/r07b"; rc_es 1; cuenta_es "^LISTO:" 0; tiene "no se pudo determinar la rama base"
fin

caso "08 rama de trabajo"
repo_nuevo r08
git -C "$S/r08" checkout -q -b feat
git -C "$S/r08" commit -q --allow-empty -m trabajo
puerta "$S/r08"; rc_es 1; tiene "está en la rama 'feat' y debería estar en 'main'"; no_tiene "sin subir"
repos "$S/r08"; tiene "[feat] PENDIENTE"; tiene "la rama no tiene upstream"
fin

caso "09 árbol sucio"
repo_nuevo r09
echo x > "$S/r09/nuevo.txt"
puerta "$S/r09"; rc_es 1; tiene "hay 1 archivo(s) sin commitear"
repos "$S/r09"; tiene "1 archivo(s) sin commitear"; tiene "PENDIENTE"
fin

caso "09b commits locales sin subir en la rama base, y stash"
repo_nuevo r09b
git -C "$S/r09b" commit -q --allow-empty -m local
echo y > "$S/r09b/t.txt"; git -C "$S/r09b" add t.txt; git -C "$S/r09b" stash -q 2>/dev/null
puerta "$S/r09b"; rc_es 1; tiene "tiene 1 commit(s) locales de 'main' sin subir"; tiene "1 stash(es)"
repos "$S/r09b"; tiene "1 commit(s) de esta rama sin subir"; tiene "stash:"
fin

# --- ROADMAP ---------------------------------------------------------------------------------------
caso "10 ROADMAP válido"
proyecto_adoptado a10; adopcion "$(ruta_p a10)"
rc_es 0; tiene "docs/ROADMAP.md: válido"; tiene "bloque Registro v1.0 (vigente)"; tiene "bloque Ciclo v1.0 (vigente)"; no_tiene "AVISO"; no_tiene "ERROR"
fin

caso "11 Lista y En revisión escritas a mano"
proyecto_adoptado a11
roadmap a11 <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | Lista |
| U1 | B | U0 | En revisión |
EOF
adopcion "$(ruta_p a11)"; rc_es 0
cuenta_es 'se calcula desde Git, no se escribe' 2
fin

caso "12 ROADMAP ausente: ERROR si está adoptado, AVISO si no; sin bloques = no adoptado"
proyecto_adoptado a12; rm -f "$S/p/a12/docs/ROADMAP.md"
adopcion "$(ruta_p a12)"; rc_es 1; tiene "ERROR: no existe docs/ROADMAP.md"
mkdir -p "$S/p/a12b/docs"; printf '# AGENTS sin nada\n' > "$S/p/a12b/AGENTS.md"
adopcion "$(ruta_p a12b)"; rc_es 1; tiene "proyecto no adoptado"; tiene "AVISO: no existe docs/ROADMAP.md"; no_tiene "ERROR: no existe docs/ROADMAP.md"
fin

caso "13 Estado en minúscula: aviso y se acepta"
proyecto_adoptado a13
roadmap a13 <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | pendiente |
EOF
adopcion "$(ruta_p a13)"; rc_es 0; tiene "usar «Pendiente»"; no_tiene "no reconocido"
fin

caso "13b Estado con detalle y Estado desconocido"
proyecto_adoptado a13b
roadmap a13b <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | Completada (PR 44) |
| U1 | B | U0 | Quizás |
EOF
adopcion "$(ruta_p a13b)"; rc_es 1; tiene "Estado con detalle en U0"; tiene "Estado no reconocido en U1"
fin

caso "14 tabla sin barra final de línea"
proyecto_adoptado a14
roadmap a14 <<'EOF'
| ID | Entrega | Depende de | Estado
| --- | --- | --- | ---
| U0 | A | — | Completada
| U1 | B | U0 | Pendiente
EOF
adopcion "$(ruta_p a14)"; rc_es 0; no_tiene "falta"; no_tiene "no reconocido"; tiene "docs/ROADMAP.md: válido"
fin

caso "15 ID repetido"
proyecto_adoptado a15
roadmap a15 <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | Completada |
| U0 | B | — | Pendiente |
EOF
adopcion "$(ruta_p a15)"; rc_es 1; tiene "ID repetido: U0"
fin

caso "16 ID mal formado"
proyecto_adoptado a16
roadmap a16 <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| 1x | A | — | Completada |
| U 2 | B | — | Pendiente |
EOF
adopcion "$(ruta_p a16)"; rc_es 1; tiene "ID mal formado: «1x»"; tiene "ID mal formado: «U 2»"
fin

caso "17 dependencias circulares (A→B→A y C→C), sin colgarse"
proyecto_adoptado a17
roadmap a17 <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| A | x | B | Pendiente |
| B | y | A | Pendiente |
| C | z | C | Pendiente |
| D | w | A | Pendiente |
EOF
adopcion "$(ruta_p a17)"; rc_es 1; tiene "dependencia circular: A → B → A"; tiene "dependencia circular: C → C"
fin

caso "18 dependencias externas con prefijo (AUTH-3) y de texto libre (Node)"
proyecto_adoptado a18
roadmap a18 <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | Completada |
| U1 | B | AUTH-3, Node, bucket | Pendiente |
| U2 | C | U0; U1 | Pendiente |
EOF
adopcion "$(ruta_p a18)"; rc_es 0; no_tiene "AVISO"; no_tiene "ERROR"
fin

caso "19 dependencia con forma de ID que no existe (P9)"
proyecto_adoptado a19
roadmap a19 <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | P9 | Pendiente |
EOF
adopcion "$(ruta_p a19)"; rc_es 0; tiene "AVISO: ROADMAP.md, línea"; tiene "«P9», que no existe en la tabla (¿error de tipeo o externa?)"
fin

caso "20 varias tablas: la de unidades primero, la posterior se ignora"
proyecto_adoptado a20
{ cab; cat <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | Completada |

Otra tabla:

| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | repetido | ZZ9 | Inventado |
| X y | mal | — | Nada |
EOF
} > "$S/p/a20/docs/ROADMAP.md"
adopcion "$(ruta_p a20)"; rc_es 0; no_tiene "ERROR"; no_tiene "AVISO"; tiene "docs/ROADMAP.md: válido"
fin

caso "21 cabecera ausente y en orden distinto (ERROR si está adoptado, AVISO si no)"
proyecto_adoptado a21
{ printf '# Hoja\n\nQué sigue: y\n**Qué lo bloquea:** nada\n**Dónde está:** x\n\n'; cat <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | Completada |
EOF
} > "$S/p/a21/docs/ROADMAP.md"
adopcion "$(ruta_p a21)"; rc_es 1; tiene "ERROR: ROADMAP.md sin la línea «**Qué sigue:**»"
proyecto_adoptado a21b
{ printf '# Hoja\n\n**Qué sigue:** y\n**Dónde está:** x\n**Qué lo bloquea:** nada\n\n'; cat <<'EOF'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | Completada |
EOF
} > "$S/p/a21b/docs/ROADMAP.md"
adopcion "$(ruta_p a21b)"; rc_es 1; tiene "ERROR: ROADMAP.md: la cabecera debe ir en el orden"; no_tiene "sin la línea"
proyecto_adoptado a21c; printf '# AGENTS sin nada\n' > "$S/p/a21c/AGENTS.md"
cp "$S/p/a21/docs/ROADMAP.md" "$S/p/a21c/docs/ROADMAP.md"
adopcion "$(ruta_p a21c)"; rc_es 1; tiene "AVISO: ROADMAP.md sin la línea «**Qué sigue:**»"; no_tiene "ERROR: ROADMAP.md sin la línea"
fin

caso "22 marcadores: ambos vigentes, desactualizado, anterior y Ciclo sin Registro"
proyecto_adoptado a22
printf '<!-- orquestacion:registro v0.9 -->\n<!-- /orquestacion:registro -->\n<!-- orquestacion:ciclo v1.0 -->\n<!-- /orquestacion:ciclo -->\n' > "$S/p/a22/AGENTS.md"
adopcion "$(ruta_p a22)"; rc_es 0; tiene "bloque Registro v0.9 y la versión vigente es v1.0 (desactualizado)"; tiene "bloque Ciclo v1.0 (vigente)"
proyecto_adoptado a22b
printf '<!-- orquestacion:bloque v1.0 -->\n' > "$S/p/a22b/AGENTS.md"
adopcion "$(ruta_p a22b)"; rc_es 0; tiene "marcador anterior"; tiene "pasar a los dos bloques"; no_tiene "ERROR"
proyecto_adoptado a22c
printf '<!-- orquestacion:ciclo v1.0 -->\n<!-- /orquestacion:ciclo -->\n' > "$S/p/a22c/AGENTS.md"
adopcion "$(ruta_p a22c)"; rc_es 0; tiene "bloque Ciclo sin el bloque Registro"; tiene "bloque Registro (ausente)"
proyecto_adoptado a22d
printf '## Orquestación\ntexto\n' > "$S/p/a22d/AGENTS.md"
adopcion "$(ruta_p a22d)"; rc_es 0; tiene "sin marcadores de versión"; no_tiene "no adoptado"
fin

caso "24 línea en blanco dentro de la tabla: AVISO una vez por bloque"
proyecto_adoptado a24
{ cab; cat <<'EOT'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | Completada |

| U1 | B | U0 | Pendiente |
| U2 | C | U1 | Pendiente |
EOT
} > "$S/p/a24/docs/ROADMAP.md"
adopcion "$(ruta_p a24)"; rc_es 0
tiene "fila de tabla después de una línea en blanco: Markdown la separa de la tabla de unidades; quitá la línea en blanco"
cuenta_es "fila de tabla después" 1; no_tiene "ERROR"
fin

caso "24b tabla nueva completa después: silencio"
proyecto_adoptado a24b
{ cab; cat <<'EOT'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | Completada |

| Otra | Cosa |
| --- | --- |
| x | y |
| z | w |
EOT
} > "$S/p/a24b/docs/ROADMAP.md"
adopcion "$(ruta_p a24b)"; rc_es 0; no_tiene "AVISO"; no_tiene "ERROR"; tiene "docs/ROADMAP.md: válido"
fin

caso "25 \| dentro de una celda: ERROR claro, sin Estado no reconocido"
proyecto_adoptado a25
roadmap a25 <<'EOT'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A \| B | — | Completada |
| U1 | C | U0 | Pendiente |
EOT
adopcion "$(ruta_p a25)"; rc_es 1
tiene 'hay un `\|` dentro de una celda; no uses | en el contenido de la tabla (ni escapado), cambiá el texto'
tiene "ROADMAP.md, línea 9:"; no_tiene "no reconocido"; cuenta_es "ERROR" 1
fin

caso "26 BOM al inicio de ROADMAP.md y AGENTS.md: sin falso aviso"
proyecto_adoptado a26
{ printf '\xEF\xBB\xBF'; cab; cat <<'EOT'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | A | — | Completada |
EOT
} > "$S/p/a26/docs/ROADMAP.md"
{ printf '\xEF\xBB\xBF'; cat "$S/p/a24/AGENTS.md"; } > "$S/p/a26/AGENTS.md"
adopcion "$(ruta_p a26)"; rc_es 0; no_tiene "sin la línea"; no_tiene "AVISO"; no_tiene "ERROR"; tiene "docs/ROADMAP.md: válido"
fin

caso "27 cabecera ausente: ver caso 21 (ERROR adoptado / AVISO no adoptado)"
adopcion "$(ruta_p a21)"; rc_es 1; tiene "ERROR: ROADMAP.md sin la línea"
adopcion "$(ruta_p a21c)"; tiene "AVISO: ROADMAP.md sin la línea"; no_tiene "ERROR: ROADMAP.md sin la línea"
fin

caso "28 Ciclo ausente: INFO que no suma a avisos ni errores"
proyecto_adoptado a28
printf '<!-- orquestacion:registro v1.0 -->\nr\n<!-- /orquestacion:registro -->\n' > "$S/p/a28/AGENTS.md"
adopcion "$(ruta_p a28)"; rc_es 0
tiene "INFO: bloque Ciclo no adoptado (recomendado, no obligatorio en el perfil «compatible con panel»)"
no_tiene "AVISO"; no_tiene "ERROR"; tiene "Resumen: 0 error(es), 0 aviso(s)"
fin

caso "29 marcador sin cerrar: ERROR"
proyecto_adoptado a29
printf '<!-- orquestacion:registro v1.0 -->\nr\n<!-- orquestacion:ciclo v1.0 -->\nc\n<!-- /orquestacion:ciclo -->\n' > "$S/p/a29/AGENTS.md"
adopcion "$(ruta_p a29)"; rc_es 1; tiene "ERROR: AGENTS.md: marcador sin cierre: falta <!-- /orquestacion:registro -->"; no_tiene "orquestacion:ciclo -->"; cuenta_es "marcador sin cierre" 1
printf '<!-- orquestacion:registro v1.0 -->\n<!-- /orquestacion:registro -->\n<!-- orquestacion:ciclo v1.0 -->\n' > "$S/p/a29/AGENTS.md"
adopcion "$(ruta_p a29)"; rc_es 1; tiene "marcador sin cierre: falta <!-- /orquestacion:ciclo -->"
fin

caso "30 placeholders <...> sin completar: AVISO una vez"
proyecto_adoptado a30
{ printf '# Hoja\n\n**Dónde está:** <una línea con el estado>\n**Qué sigue:** y\n**Qué lo bloquea:** nada\n\n'; cat <<'EOT'
| ID | Entrega | Depende de | Estado |
| --- | --- | --- | --- |
| U0 | <entrega> | — | Completada |
| U1 | <entrega> | U0 | Pendiente |
EOT
} > "$S/p/a30/docs/ROADMAP.md"
adopcion "$(ruta_p a30)"; rc_es 0; tiene "AVISO: ROADMAP.md tiene marcas <...> sin completar"; cuenta_es "sin completar" 1; no_tiene "ERROR"
fin

caso "31 AGENTS.md ausente con CLAUDE.md presente: mensaje orientador"
proyecto_adoptado a31; rm -f "$S/p/a31/AGENTS.md"; printf '# instrucciones\n' > "$S/p/a31/CLAUDE.md"
adopcion "$(ruta_p a31)"; rc_es 1
tiene "ERROR: no existe AGENTS.md (hay CLAUDE.md; si ese es el archivo de instrucciones del agente, el bloque va ahí)"
printf '## Orquestación\n' >> "$S/p/a31/CLAUDE.md"
adopcion "$(ruta_p a31)"; rc_es 0; tiene "AVISO: no existe AGENTS.md (hay CLAUDE.md"
proyecto_adoptado a31b; rm -f "$S/p/a31b/AGENTS.md"
adopcion "$(ruta_p a31b)"; rc_es 1; tiene "ERROR: no existe AGENTS.md"; no_tiene "hay "
fin

# --- estado-vivo ---------------------------------------------------------------------------------------
caso "23 estado-vivo sin PR fusionados (gh simulado): no imprime null"
if ! command -v jq >/dev/null 2>&1; then
	echo "OMITIDO 23 (falta jq)"; MALO=0; OKS=$((OKS+1))
else
	repo_nuevo r23
	cat > "$S/bin/gh" <<'EOF'
#!/usr/bin/env bash
# gh simulado: aplica el filtro --jq sobre JSON fijo (GH_ABIERTOS / GH_FUSIONADOS según --state).
estado=""; filtro=""
while [ "$#" -gt 0 ]; do
	case "$1" in --state) estado="$2"; shift ;; --jq) filtro="$2"; shift ;; esac
	shift
done
if [ "$estado" = open ]; then json="${GH_ABIERTOS:-[]}"; else json="${GH_FUSIONADOS:-[]}"; fi
printf '%s' "$json" | jq -r "$filtro" | tr -d '\r'
EOF
	chmod +x "$S/bin/gh"
	OUT="$(PATH="$S/bin:$PATH" ESTADO_DIR="$S/estado" bash "$SCR/estado-vivo.sh" "$S/r23" 2>&1)"; RC=$?
	rc_es 0; no_tiene "null"; tiene "| r23 | \`main\` | 0 | LISTO | ninguno | — |"
	[ -f "$S/estado/ESTADO-VIVO.md" ] || { DETALLE="$DETALLE
     no se escribió ESTADO-VIVO.md"; MALO=1; }
	OUT="$(PATH="$S/bin:$PATH" ESTADO_DIR="$S/estado" GH_ABIERTOS='[{"number":3,"title":"uno | dos"}]' \
		GH_FUSIONADOS='[{"number":7,"title":"ñandú | ok","mergedAt":"2026-01-02T03:04:05Z"}]' \
		bash "$SCR/estado-vivo.sh" --solo-archivo "$S/r23" 2>&1; cat "$S/estado/ESTADO-VIVO.md")"
	tiene '#3 uno \| dos'; tiene '#7 ñandú \| ok (2026-01-02T03:04)'; no_tiene "null"
fi
fin

caso "23b estado-vivo: repo sin remoto y worktree no rompen"
OUT="$(PATH="$S/bin:$PATH" ESTADO_DIR="$S/estado" bash "$SCR/estado-vivo.sh" "$S/r05" "$S/wt04" 2>&1)"; RC=$?
rc_es 0; tiene "| r05 |"; tiene "| wt04 |"; no_tiene "repositorio no encontrado"
fin

echo
echo "Resumen: $OKS bien, $FALLAS con falla."
[ "$FALLAS" = 0 ]
