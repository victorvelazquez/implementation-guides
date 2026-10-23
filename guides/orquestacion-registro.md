---
id: orquestacion-registro
title: Orquestación — Registro de trabajo
last_verified: 2026-10-23
applies_when:
  - un proyecto quiere que su lista de tareas, sus avances y sus pendientes se lean igual en cualquier lado (personas, agentes, paneles, scripts)
  - se quiere que el proyecto aparezca con su avance en un panel de estado
not_when:
  - el proyecto es un experimento de un solo día que no va a tener más de una unidad de trabajo
verified_with:
  - Git y GitHub CLI; usado de forma informal en un conjunto pequeño de proyectos durante pocas horas; sin adopción formal completa (poco tiempo de prueba)
---

# Orquestación — Registro de trabajo

> Que cada proyecto diga, en un archivo con formato fijo, qué se hizo, qué se está haciendo y qué sigue.

Es el método **base** de la familia Orquestación y el que necesita un proyecto independiente para ser legible por un panel. Los otros métodos (Ciclo, Dirección, Enlace) se apoyan en este.

## 1. Cuándo aplica

- **Aplica** si: el proyecto tiene más de un puñado de unidades de trabajo, o lo trabajan agentes o varias personas.
- **No aplica** si: es una prueba descartable. Con pocas tareas alcanza una lista en el README.

## 2. Reglas

| ID | Nivel | Regla | Por qué |
| --- | --- | --- | --- |
| REG-1 | MUST | Seis estados: `Pendiente`, `En curso`, `Lista` (hecha y verificada en el árbol, sin entregar), `En revisión` (PR abierto), `Completada` (cerrada en el diff de su unidad; **vale desde que el PR se fusiona**) y `Bloqueada` (con motivo). En la tabla escrita a mano, `Estado` es **una sola palabra** entre `Pendiente`, `En curso`, `Completada` y `Bloqueada`. `Lista` y `En revisión` **no se escriben**: se calculan desde Git y desde el alojamiento | Un lector automático no entiende texto libre; y un estado escrito a mano que depende de un PR queda desactualizado al fusionar |
| REG-2 | MUST | `docs/ROADMAP.md` con una cabecera de tres líneas (`**Dónde está:**`, `**Qué sigue:**`, `**Qué lo bloquea:**`, en ese orden) y una tabla. Columnas obligatorias: `ID`, `Entrega`, `Depende de`, `Estado`. Opcionales: `Resultado visible`, `Notas`, `Ficha`. Plantilla: `templates/orquestacion/ROADMAP.md` | Es el contrato que leen los paneles y los agentes nuevos |
| REG-3 | MUST | `ID` único dentro de la tabla, con la forma `[A-Za-z][A-Za-z0-9._-]*`. Las dependencias se escriben por ID, separadas por coma, o `—` si no hay. Una dependencia no puede ser circular | Sin IDs únicos y sin ciclos no se puede calcular qué sigue |
| REG-4 | MUST | Al cerrar una unidad, **en el mismo diff** que la implementa: su fila pasa a `Completada`, la cabecera se actualiza y la ficha se cierra | Así, al fusionar, el repositorio ya dice la verdad. Si no, miente hasta que otra unidad lo corrija |
| REG-5 | SHOULD | Una ficha por unidad en `odd/tasks/<unidad>.md` (plantilla `ficha-unidad.md`): especificaciones numeradas `S#` con las palabras exactas de la persona, tareas y bitácora | Permite retomar una unidad sin reconstruir la conversación |
| REG-6 | SHOULD | Comando `siguiente`: toma la primera fila `Pendiente` cuyas dependencias **que son filas de la tabla** estén `Completada`. Las dependencias que no son filas (otro proyecto, una herramienta, una decisión de la persona) son **informativas**: se muestran y no bloquean. `siguiente <ID>` fuerza esa unidad (si no se puede, se detiene y lo dice); `siguiente?` solo informa. Antes de empezar, el árbol debe estar limpio y en la rama base | Evita decidir a ciegas qué sigue, sin trabar un proyecto por algo que solo otra parte puede resolver |
| REG-7 | SHOULD | El estado vive **en el repositorio del proyecto**. Quien lo necesita (una sala, un panel) lo **lee de la rama base remota** (`origin/<base>`) y no lo copia a otro lado. El árbol de trabajo solo se mira para detectar `Lista` | Dos copias se desalinean; y leer el árbol de trabajo mostraría `Completada` una unidad con el PR todavía abierto |
| REG-8 | SHOULD | El ID de la unidad va en el nombre de la rama o en el título del PR, como **token completo** sin distinguir mayúsculas: separado por `/`, `-`, `_` o espacio (`p2-cabecera`, `feat/p2-cabecera`, «P2: cabecera»; `p20-x` no cuenta como `p2`). `En curso` no se escribe: se deriva de esa misma asociación | Es la única forma de asociar una unidad con su rama o su PR para calcular `Lista` y `En revisión` |
| REG-9 | MAY | Usar la columna `Notas` para el número de PR, los bloqueos y los detalles que no caben en `Estado` | Mantiene `Estado` legible por máquina |

## 3. Alternativas y criterio para elegir

| Opción | Conviene cuando | Costo |
| --- | --- | --- |
| `docs/ROADMAP.md` (esta guía) | Trabajan agentes, o se quiere compatibilidad con paneles y scripts | Hay que mantenerlo en cada unidad |
| Tablero del alojamiento (issues, proyectos) | Equipo grande y humano | Los agentes lo leen peor; no viaja con el código |
| Ambos | Se usa un tablero externo por costumbre | El `ROADMAP.md` es el espejo legible; en caso de duda manda el repositorio |

## 4. Cómo implementarlo

1. Copiar `templates/orquestacion/ROADMAP.md` a `docs/ROADMAP.md` y completar la cabecera y las unidades vigentes.
2. **Proyecto con tareas en otros formatos:** no reescribir el historial. Crear un `ROADMAP.md` corto con las unidades vigentes y dejar lo anterior como archivo, con un enlace desde la cabecera.
3. Copiar la plantilla de ficha a `odd/tasks/` y usarla desde la próxima unidad.
4. Agregar al `AGENTS.md` el bloque **Registro** (`templates/orquestacion/AGENTS-bloque-registro.md`). Es el bloque mínimo; el de **Ciclo** es opcional (ver la guía Ciclo).
5. Registrar la adopción en `docs/ORQUESTACION.md` (plantilla `registro-de-adopcion.md`).
6. **Proyecto independiente, sin sala:** copiar `scripts/orquestacion/` (junto con `lib.sh` y `VERSION`) a una carpeta del proyecto o a una de herramientas. Los scripts aceptan una ruta sin necesitar `proyectos.conf`.

## 5. Cómo verificar que quedó bien

```bash
bash scripts/orquestacion/verificar-adopcion.sh <ruta-del-proyecto>
```

| Regla | Cómo se comprueba |
| --- | --- |
| REG-1 | El control avisa si `Estado` trae algo distinto de las cuatro palabras, o si `Lista`/`En revisión` están escritas a mano |
| REG-2 | El control exige la cabecera de tres líneas en orden y las columnas obligatorias |
| REG-3 | El control informa IDs repetidos, mal formados y dependencias circulares |
| REG-4 | A mano, en la revisión de cada unidad: el diff de la unidad toca su fila del `ROADMAP.md` |

Un `ROADMAP.md` ausente en un proyecto que adoptó el bloque es un **error**.

## 6. Problemas conocidos

| Síntoma | Causa | Solución |
| --- | --- | --- |
| Un lector no entiende `Completada (PR 44)` | El detalle está dentro de `Estado` | Dejar la palabra en `Estado` y el detalle en `Notas`. Los lectores tolerantes igual toman la primera palabra y avisan |
| Dos formatos de tareas conviven y nadie sabe cuál manda | Se adoptó el estándar sin retirar el anterior | El `ROADMAP.md` manda; lo anterior queda como archivo, con enlace |
| Un panel muestra `Completada` una unidad con el PR abierto | El lector mira el árbol de trabajo y no la rama base remota | REG-7 |
| La unidad parece no tener siguiente | Todas las pendientes dependen de filas aún no completadas | Mirar `Depende de`; si es un bloqueo externo, marcarlo `Bloqueada` con nota |
| `siguiente` queda trabado por «Node» o por otro proyecto | Se trató una dependencia externa como bloqueante | REG-6: lo externo es informativo |

## 7. No verificado

- La lectura de este formato por un panel concreto está **especificada** pero no implementada.
- El vínculo unidad→rama/PR (REG-8) es una convención; no se probó con un panel.
- El método se probó pocas horas, en un solo conjunto de proyectos.

## 8. Desviaciones

Si el proyecto se aparta de un `MUST` o un `SHOULD`, anotar en su `docs/ORQUESTACION.md` qué cambió, por qué y quién lo decidió.
