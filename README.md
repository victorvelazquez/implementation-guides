# Implementation Guides

Guías de implementación **independientes del proyecto**, escritas para que una IA (o una persona) las lea y las aplique. Cada guía recoge una forma de hacer algo que ya se probó en proyectos reales, con las condiciones en que conviene, las alternativas y lo que **no** se verificó.

Son **preferencias, no órdenes**: un punto de partida con criterio. Si el proyecto necesita otra cosa, se elige otra cosa y se deja anotado.

## Guías disponibles

| Guía | Para qué | Cuándo leerla |
| --- | --- | --- |
| [CI con GitHub Actions](guides/ci-github-actions.md) | Pruebas automáticas en cada PR | Al crear un proyecto o cuando aún no tiene CI |
| [Ramas y métodos de merge](guides/branching-and-merge.md) | Estrategia de ramas y cuándo usar merge commit, squash o rebase | Al definir el flujo de trabajo del repositorio |
| [Versionado y releases](guides/versioning-and-releases.md) | Versiones, tags, changelog y releases calculados desde los commits | Al preparar la primera versión o automatizar las siguientes |

Los archivos listos para copiar están en [`templates/`](templates/). Para escribir una guía nueva, usar [`_TEMPLATE.md`](_TEMPLATE.md).

## Categorías

| Categoría | Guías |
| --- | --- |
| Proceso de trabajo y coordinación (Orquestación) | [Registro](guides/orquestacion-registro.md) · [Ciclo](guides/orquestacion-ciclo.md) · [Dirección](guides/orquestacion-direccion.md) · [Enlace](guides/orquestacion-enlace.md) · [Herramientas](guides/orquestacion-herramientas.md) · [Adopción](guides/orquestacion-adopcion.md) |
| Calidad e integración continua | [CI con GitHub Actions](guides/ci-github-actions.md) |
| Ramas, versionado y releases | [Ramas y métodos de merge](guides/branching-and-merge.md) · [Versionado y releases](guides/versioning-and-releases.md) |

El índice completo, legible por máquina, está en [`index.json`](index.json).

## Perfiles de adopción

Un perfil es un conjunto de guías que se adoptan juntas. Para empezar, ver [Adopción](guides/orquestacion-adopcion.md).

| Perfil | Para quién |
| --- | --- |
| Proyecto independiente | Proyecto sin sala que quiere publicar su avance de forma estándar |
| Con sala | Varios proyectos que se consumen entre sí |
| Proyecto nuevo | Arranca de cero: guías vecinas y luego el perfil que corresponda |
| Proyecto existente | Auditoría primero, sin reescribir el historial |

## Panel de estado (opcional)

Si querés ver varios proyectos en un solo lugar, existe [`repo-panel`](https://github.com/victorvelazquez/repo-panel), un panel local opcional. **Lo que el panel necesita de un proyecto lo define y lo comprueba el propio panel** (su `requirements.json` y su `requirements/INSTALL.md`), no estas guías: para poner un proyecto en condiciones, instalá el panel y usá su orden «Put in conditions». Estas guías describen el método de trabajo (Registro, Ciclo, Dirección y Enlace) y funcionan igual sin el panel.

## Cómo pedirle a una IA que use una guía

Basta con mencionar el archivo:

```text
Leé guides/versioning-and-releases.md de implementation-guides y aplicalo a este proyecto.
```

Funciona con una ruta local o con la URL del archivo en bruto:
`https://raw.githubusercontent.com/victorvelazquez/implementation-guides/main/guides/<guía>.md`

Para adoptar un perfil completo:

```text
Leé guides/orquestacion-adopcion.md de implementation-guides y aplicá el perfil «proyecto independiente» a este proyecto.
```

La IA deja el registro de lo adoptado en `docs/ORQUESTACION.md` del proyecto y anota las desviaciones.

## Protocolo para la IA que aplica una guía

1. **Prioridad.** Mandan, en este orden: la instrucción explícita de la persona, las reglas del propio proyecto (`AGENTS.md`, `CONTRIBUTING`, convenciones del repositorio) y, por último, la guía. Si la guía choca con alguna de las dos primeras, gana la otra.
2. **Mirar antes de aplicar.** Revisar el proyecto real: lenguaje y gestor de paquetes, si el repositorio es público o privado, el plan de GitHub, qué herramientas ya usa. Comprobar con la sección "Cuándo aplica" si la guía encaja.
3. **Entender las palabras clave.**
   - `MUST`: aplicar siempre, salvo que choque con el punto 1 o rompa el proyecto.
   - `SHOULD`: valor por defecto. Se puede cambiar si hay una razón concreta.
   - `MAY`: opcional.
4. **Libertad para elegir otra cosa.** Si el proyecto requiere otras herramientas o cualidades, usar la opción más adecuada, apoyándose en la sección "Alternativas" de la guía. La guía no obliga a usar sus herramientas.
5. **Anotar las desviaciones.** Si se aparta de un `MUST` o de un `SHOULD`, dejar una línea en el proyecto (README, documento de decisiones o descripción del PR): qué se cambió y por qué. Nunca en silencio.
6. **No copiar a ciegas.** Cada guía lleva una fecha de verificación y comandos para volver a consultar versiones. Verificarlas antes de usarlas.
7. **Pedir confirmación en lo irreversible o público.** Publicar un repositorio, cambiar la configuración de GitHub o tocar ramas protegidas son decisiones de la persona.
8. **Respetar la sección "No verificado".** Lo que figura ahí no se afirma como cierto: se prueba y, si se confirma, se actualiza la guía.

## Cómo crece este repositorio

- Una guía por tema, corta, con la misma estructura (ver `_TEMPLATE.md`).
- Se agrega una guía cuando un patrón se probó en un proyecto real; lo no probado va a "No verificado".
- Se actualiza la fecha de verificación cada vez que se vuelve a comprobar.

## Licencia

MIT. Ver [LICENSE](LICENSE).
