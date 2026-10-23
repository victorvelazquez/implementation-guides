# Tablero de <conjunto de proyectos>

Actualizado: <fecha>. **Meta:** <hito y fecha, si hay>.

## Cómo se usa

- Este tablero es la versión **curada**: decisiones, orden y riesgos. **No copia el estado de las unidades**: el estado vive en el `docs/ROADMAP.md` de cada proyecto y se lee de la rama base remota con `git show origin/<base>:docs/ROADMAP.md`; `scripts/orquestacion/estado-vivo.sh` muestra el estado de los repositorios (rama, cambios, puerta, PR), no el de las unidades, y su salida no se versiona. Acá se anota *por qué* una unidad importa y en qué orden conviene hacerlas.
- La sala lo actualiza **sin preguntar** en cada evento de ciclo (un proyecto avisa «LISTO PARA CICLO NUEVO», se registra una decisión, cambia el plan) e informa en una línea qué cambió.
- Estados (los de la guía Registro): `Pendiente`, `En curso`, `Completada`, `Bloqueada`; `Lista` y `En revisión` se calculan desde Git.

## Puertas de control

| Fecha | Qué debe estar | Si no está |
| --- | --- | --- |
| <fecha> | <condición> | <qué se recorta> |

## Foco actual por proyecto

Una fila por proyecto: qué unidad importa ahora y qué destraba.

| Proyecto | Unidad en foco | Por qué importa / qué destraba | Hoja de ruta |
| --- | --- | --- | --- |
| <proyecto A> | <A-3> | <destraba a B-2> | [`docs/ROADMAP.md`](<ruta o URL>) |

## Tareas de la persona (en orden de impacto)

1. <entrega o decisión que más destraba>
2. <siguiente>

## Siguiente paso, por proyecto

| Proyecto | Qué sigue | Quién actúa |
| --- | --- | --- |
| <proyecto> | <qué sigue> | <persona | sesión> |

## Mejoras posteriores (no autorizadas todavía)

- <idea>
