# Scripts de coordinación

Cuatro scripts de Bash para ver el estado de varios repositorios sin abrirlos uno por uno.

## Qué necesitás

- Git y Bash (en Windows, el de Git for Windows).
- Opcionales, solo para `estado-vivo.sh`: `gh` (PR abiertos y fusionados) y `jq`. Sin ellos esas columnas quedan vacías.

## Qué hace cada script

| Script | Para qué | Qué escribe |
| --- | --- | --- |
| `puerta-de-ciclo.sh <prefijo o ruta>` | Dice LISTO o NO LISTO para arrancar una unidad nueva (rama base, árbol limpio, al día con el remoto, sin stash). Sale con 0 o 1. | Nada en el árbol ni en el índice. Hace `git fetch`, que actualiza las referencias remotas dentro de `.git`. |
| `verificar-repos.sh [prefijo o ruta ...]` | Qué queda realmente pendiente de entregar: cambios sin commitear, commits sin subir, stash. | Nada (también hace `git fetch`). |
| `estado-vivo.sh [--solo-archivo] [prefijo o ruta ...]` | Tabla con el estado vivo de todos los proyectos. | Solo este script escribe un archivo: `ESTADO-VIVO.md` en `$ESTADO_DIR` (por defecto `.estado/` junto a los scripts, no se versiona). |
| `verificar-adopcion.sh [--remoto] [prefijo o ruta ...]` | Revisa `AGENTS.md` (bloques de Orquestación) y `docs/ROADMAP.md` de cada proyecto. Con `--remoto` valida `origin/<base>:docs/ROADMAP.md` (lo que leen el panel y la sala) con las referencias locales, sin `fetch`; en modo normal avisa si el árbol local difiere del remoto. Sale con 1 si hay errores; avisos e INFO no cambian el código. | Nada. |

## Cómo se llaman

Con una ruta (`bash puerta-de-ciclo.sh C:/ruta/al/repo`, no necesita `proyectos.conf`) o con un `<prefijo>` que figure en `proyectos.conf`. Sin argumentos, `verificar-repos.sh`, `estado-vivo.sh` y `verificar-adopcion.sh` recorren todos los proyectos del archivo.

## Armar `proyectos.conf`

1. Copiá `proyectos.conf.example` a `proyectos.conf` (junto a los scripts).
2. Una línea por proyecto: `prefijo|ruta|nombre|rol` (rol `sala` para Dirección, `proyecto` para el resto).
3. Las rutas relativas se resuelven contra `RAIZ_PROYECTOS` (si no está definida, contra la carpeta de los scripts, no contra donde corrés el comando). Ante la duda, usá rutas absolutas.

## Pruebas

```
bash pruebas/probar.sh
```

Tarda unos 40 segundos. Crea repositorios temporales solo en `.tmp-pruebas/` (dentro de esta carpeta), los borra al terminar y sale con código distinto de 0 si algún caso falla. No toca ningún repositorio real.

## Advertencia al copiar la carpeta

Copiar la carpeta completa trae también `pruebas/` y `limpieza-de-sesiones/`. La limpieza es solo para Gentle Shell en Windows y se puede omitir; las pruebas se pueden omitir si no vas a modificar los scripts.
