#!/usr/bin/env bash
# Adopta el método Registro en un proyecto: crea lo que falta desde las plantillas del paquete.
# Uso:  bash adoptar.sh [--solo-mostrar] [ruta del proyecto]     (sin ruta, el directorio actual)
#   --solo-mostrar  simula: dice qué haría y no escribe nada (tampoco corre el control).
#
# Qué hace (todo idempotente: una segunda corrida no cambia nada):
#   - AGENTS.md: si falta, lo crea con el bloque Registro; si existe, agrega el bloque al final SIN tocar lo que
#     ya tiene (conserva BOM y CRLF). Si ya hay un bloque «orquestacion:registro» no lo duplica; si es de otra
#     versión, avisa y no lo pisa.
#   - docs/ROADMAP.md y docs/ORQUESTACION.md: los crea desde las plantillas solo si faltan. Un ROADMAP.md
#     existente NO se pisa (se avisa y se remite a la auditoría de la guía de adopción).
#   - No usa el índice de git ni hace commit. Al final corre verificar-adopcion.sh y sale con su código.
# Las plantillas se buscan en ../../templates/orquestacion (o en $PLANTILLAS_DIR).
# Códigos: 0 bien (o simulación), 1 el control encontró errores, 2 uso incorrecto o faltan plantillas.
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLANT="${PLANTILLAS_DIR:-$AQUI/../../templates/orquestacion}"

SOLO=0; RUTA=""; DIO_RUTA=0
for a in "$@"; do
	case "$a" in
		--solo-mostrar) SOLO=1 ;;
		--*) echo "Opción desconocida: $a" >&2; exit 2 ;;
		*) [ "$DIO_RUTA" = 0 ] || { echo "Sobra un argumento: $a (se espera una sola ruta)" >&2; exit 2; }; DIO_RUTA=1; RUTA="$a" ;;
	esac
done
[ "$DIO_RUTA" = 0 ] || [ -n "$RUTA" ] || { echo "La ruta vacía no es válida: pasar una carpeta o no pasar nada (directorio actual)." >&2; exit 2; }
RUTA="${RUTA:-.}"
[ -d "$RUTA" ] || { echo "La carpeta no existe: $RUTA" >&2; exit 2; }
D="$(cd "$RUTA" && pwd)"
for f in AGENTS-bloque-registro.md ROADMAP.md registro-de-adopcion.md; do
	[ -f "$PLANT/$f" ] || { echo "Falta la plantilla $PLANT/$f (copiar templates/orquestacion junto a scripts/, o fijar PLANTILLAS_DIR)." >&2; exit 2; }
done
NOMBRE="$(basename "$D")"
HOY="$(date +%Y-%m-%d)"

# Bloque Registro de la plantilla (de la apertura al cierre, sin CR).
bloque="$(tr -d '\r' < "$PLANT/AGENTS-bloque-registro.md" | awk '/<!-- orquestacion:registro v/{p=1} p{print} /<!-- \/orquestacion:registro -->/{p=0}')"
vbloque="$(printf '%s\n' "$bloque" | grep -o 'orquestacion:registro v[0-9][0-9.]*' | head -1)"; vbloque="${vbloque##*v}"
[ -n "$bloque" ] && [ -n "$vbloque" ] || { echo "La plantilla AGENTS-bloque-registro.md no tiene el bloque con marcadores." >&2; exit 2; }

HICE=0; FALLO=0
dice() { if [ "$SOLO" = 1 ]; then echo "   crearía/agregaría: $1"; else echo "   $1"; fi; }
nota() { echo "   $1"; }
fallo() { echo "   ERROR: no se pudo escribir $1 (¿permisos, o hay un archivo donde debería haber una carpeta?)"; FALLO=1; }

# Copia una plantilla ($1) a $2 sin CR y con <proyecto> y <fecha> reemplazados como TEXTO LITERAL
# (un nombre con & o \ no se interpreta). Solo si no es simulación.
desde_plantilla() {
	[ "$SOLO" = 1 ] && return 0
	mkdir -p "$(dirname "$2")" && ADO_N="$NOMBRE" ADO_F="$HOY" awk '
		function rep(s, a, b,   o, i) { o = ""; while ((i = index(s, a)) > 0) { o = o substr(s, 1, i-1) b; s = substr(s, i + length(a)) } return o s }
		{ gsub(/\r/, ""); print rep(rep($0, "<proyecto>", ENVIRON["ADO_N"]), "<fecha>", ENVIRON["ADO_F"]) }' "$1" > "$2"
}

echo "== $NOMBRE ($D)"

# 1. AGENTS.md
ag="$D/AGENTS.md"
if [ ! -f "$ag" ]; then
	dice "crea AGENTS.md con el bloque Registro v$vbloque"
	if [ "$SOLO" = 1 ]; then HICE=1
	elif printf '# Instrucciones para agentes\n\n%s\n' "$bloque" > "$ag"; then HICE=1
	else fallo AGENTS.md; fi
else
	texto="$(sed '1s/^\xEF\xBB\xBF//' "$ag")"
	vact="$(printf '%s\n' "$texto" | grep -o 'orquestacion:registro v[0-9][0-9.]*' | head -1)"; vact="${vact##*v}"
	if [ -n "$vact" ] && [ "$vact" = "$vbloque" ]; then
		nota "AGENTS.md: el bloque Registro v$vact ya está presente: sin cambios"
	elif [ -n "$vact" ]; then
		nota "AVISO: AGENTS.md tiene el bloque Registro v$vact y el vigente es v$vbloque: no se modifica; actualizarlo a mano reemplazando lo que está entre los marcadores"
	elif printf '%s\n' "$texto" | grep -q 'orquestacion:bloque v[0-9]'; then
		nota "AVISO: AGENTS.md tiene el marcador anterior «orquestacion:bloque»: no se modifica; pasar a los bloques registro y ciclo a mano"
	else
		dice "agrega el bloque Registro v$vbloque al final de AGENTS.md (sin tocar lo existente)"
		if [ "$SOLO" = 1 ]; then HICE=1
		else
			fin=""
			# Si el archivo usa CRLF, el bloque se agrega con CRLF; si no termina en salto de línea, se lo agrega.
			if grep -q $'\r' "$ag"; then fin=$'\r'; fi
			if {
				[ -z "$(tail -c1 "$ag")" ] || printf '%s\n' "$fin"
				printf '%s\n' "$fin"
				printf '%s\n' "$bloque" | sed "s/\$/$fin/"
			} >> "$ag"; then HICE=1; else fallo AGENTS.md; fi
		fi
	fi
fi

# 2. docs/ROADMAP.md
rm_="$D/docs/ROADMAP.md"
if [ -f "$rm_" ]; then
	nota "AVISO: docs/ROADMAP.md ya existe: no se modifica. Si tiene otro formato, ver la guía guides/orquestacion-adopcion.md, sección 4 (auditoría primero, fila «docs/ROADMAP.md»): hay que dejar una sola tabla estándar con el estado"
else
	dice "crea docs/ROADMAP.md desde la plantilla (completar las marcas <...>)"
	if desde_plantilla "$PLANT/ROADMAP.md" "$rm_"; then HICE=1; else fallo docs/ROADMAP.md; fi
fi

# 3. docs/ORQUESTACION.md
reg="$D/docs/ORQUESTACION.md"
if [ -f "$reg" ]; then
	nota "docs/ORQUESTACION.md: ya existe: sin cambios"
else
	dice "crea docs/ORQUESTACION.md desde la plantilla (completar perfil y métodos)"
	if desde_plantilla "$PLANT/registro-de-adopcion.md" "$reg"; then HICE=1; else fallo docs/ORQUESTACION.md; fi
fi

echo
if [ "$SOLO" = 1 ]; then
	echo "Simulación: no se escribió nada ni se corrió el control."
	exit 0
fi
if [ "$FALLO" = 1 ]; then
	echo "Falló la escritura: la adopción quedó incompleta. Corregir la causa y volver a correr (es idempotente); no se corrió el control."
	exit 1
fi
[ "$HICE" = 1 ] && echo "Listo. Se escribió en el árbol de trabajo; no se usó el índice de git ni se hizo commit." || echo "Sin cambios: el proyecto ya tenía todo."
echo
bash "$AQUI/verificar-adopcion.sh" "$D"
