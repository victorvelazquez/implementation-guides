---
id: orquestacion-adopcion
title: Orquestación — Cómo adoptarla (perfiles)
last_verified: 2026-10-23
applies_when:
  - se quiere que un proyecto nuevo o existente empiece a trabajar con los métodos de Orquestación
not_when:
  - el proyecto ya adoptó los métodos que necesita y solo se quiere actualizar la versión de los bloques (alcanza con reemplazar los bloques del `AGENTS.md` y su número de versión)
verified_with:
  - Git y GitHub CLI; probado de forma informal en un conjunto pequeño de proyectos, con una sesión de agente por repositorio; sin adopción formal completa (poco tiempo de prueba)
---

# Orquestación — Cómo adoptarla

> Elegir qué métodos adoptar según el tipo de proyecto, y hacerlo sin reescribir lo que el proyecto ya tiene.

Los métodos son cuatro: **Registro** (qué se hizo y qué sigue), **Ciclo** (cómo se entrega una unidad), **Dirección** (la sala que coordina) y **Enlace** (cómo se avisan la sala y los proyectos). Se adopta **por método**: lo `MUST` de un método es lo que lo define; lo `SHOULD` y `MAY` se puede ajustar anotando la desviación.

## 1. Cuándo aplica

- **Aplica** si: hay que elegir qué adoptar, o llevar un proyecto existente al estándar.
- **No aplica** si: el proyecto ya está al día (solo se actualizan los bloques).

## 2. Reglas

| ID | Nivel | Regla | Por qué |
| --- | --- | --- | --- |
| ADO-1 | MUST | Elegir el **perfil** (abajo) antes de copiar nada | Cada perfil trae los métodos que se necesitan juntos |
| ADO-2 | MUST | Registrar la adopción en `docs/ORQUESTACION.md`: versión de los bloques, métodos y desviaciones | Es lo que consultan las personas; el control mira los marcadores |
| ADO-3 | MUST | **No reescribir el historial.** Lo que el proyecto ya tenía (listas de tareas, documentos de proceso) queda como archivo, con un enlace desde `docs/ROADMAP.md` | Reescribir pierde evidencia y cuesta más de lo que ahorra |
| ADO-4 | MUST | La adopción es **una unidad de documentación en un solo PR**, que arranca de un estado limpio (la puerta del método Ciclo) | Se revisa en minutos y no se mezcla con otro trabajo |
| ADO-5 | SHOULD | Adoptar en orden: Registro, luego Ciclo; Dirección y Enlace solo si hay varios proyectos | Cada método se apoya en el anterior |
| ADO-6 | SHOULD | Probar con **uno o dos proyectos piloto** antes de extenderlo a los demás | Los problemas aparecen con el uso, no leyendo |
| ADO-7 | SHOULD | Correr `verificar-adopcion.sh` al terminar | Detecta bloque desactualizado y `ROADMAP.md` inválido |
| ADO-8 | MAY | Adoptar un solo método | Útil para empezar de a poco |
| ADO-9 | MUST | Si ya existe un `docs/ROADMAP.md` **con otro formato** (tabla con otras columnas, narrativa alrededor), crear la tabla estándar y **no dejar dos tablas con el mismo estado**: la narrativa se mueve a otro archivo (con enlace desde la cabecera) o queda debajo de la tabla estándar, sin repetir estados | REG-7: el estado tiene una sola fuente; dos tablas se desalinean y el lector toma la primera que encuentra |

### Perfiles

| Perfil | Para quién | Métodos |
| --- | --- | --- |
| **Compatible con panel** | Un proyecto independiente, sin sala, que quiere publicar su avance de forma estándar | **Registro** (`MUST`); Ciclo (`SHOULD`) |
| **Con sala** | Varios proyectos que se consumen entre sí | Registro, Ciclo, **Dirección** y **Enlace** (los cuatro `MUST`) |
| **Proyecto nuevo** | Un proyecto que arranca de cero | Las guías vecinas (CI, ramas y merge, versionado) y luego el perfil que corresponda |
| **Proyecto existente** | Un proyecto con historia que quiere llegar al estándar | La auditoría de la sección 4 y luego el perfil que corresponda |

Dependencias entre métodos: **Enlace** necesita Dirección; **Dirección** necesita Registro en cada proyecto; **Ciclo** funciona solo.

## 3. Alternativas y criterio para elegir

| Opción | Conviene cuando | Costo |
| --- | --- | --- |
| Adoptar un perfil completo | Se quiere un estándar parejo | Más texto en el `AGENTS.md` |
| Adoptar solo Registro | El proyecto solo necesita aparecer en un panel | No hay reglas de entrega |
| No adoptar ninguno | Es un proyecto de un solo día | Sin coordinación posible |

## 4. Cómo implementarlo

### Compatible con panel (proyecto independiente)

1. Copiar `templates/orquestacion/ROADMAP.md` a `docs/ROADMAP.md` y completar la cabecera y las unidades vigentes.
2. Agregar al `AGENTS.md` el bloque **Registro** (`AGENTS-bloque-registro.md`) y, si se quiere, el bloque **Ciclo** sin las partes `SALA`.
3. Crear `docs/ORQUESTACION.md` con el registro de adopción.
4. Copiar `scripts/orquestacion/` (con `lib.sh` y `VERSION`) a una carpeta del proyecto o de herramientas, y correr `bash scripts/orquestacion/verificar-adopcion.sh <ruta-del-proyecto>`. No hace falta `proyectos.conf`.
5. Mostrar el proyecto en un panel de estado: hoy el panel de referencia tiene la lectura del `ROADMAP.md` **especificada pero no implementada**; hasta entonces el proyecto cumple el formato y espera.

### Con sala

1. Hacer lo anterior en cada proyecto (con los dos bloques y las partes `SALA` incluidas).
2. Crear el repositorio de la sala con `AGENTS-sala.md`, `ENLACES.md` y, si se quiere, `TABLERO.md`.
3. Copiar `scripts/orquestacion/` a la sala y completar `proyectos.conf`.
4. Mandar a cada sesión de proyecto la orden de adopción (`orden-de-adopcion.md`), **de a uno**, empezando por los proyectos que estén en un estado limpio.
5. Correr `verificar-adopcion.sh` y completar el mapa de enlaces.

### Proyecto nuevo

1. Aplicar las guías vecinas, según convenga: CI, ramas y métodos de merge, versionado y releases.
2. Crear el `AGENTS.md` con los bloques desde el primer commit.
3. Crear `docs/ROADMAP.md` con la unidad 0 (la adopción) ya `Completada` **en el mismo diff** que la agrega; vale cuando el PR se fusione.
4. Seguir el perfil que corresponda.

### Proyecto existente: auditoría primero

| Qué mirar | Si falta | Acción |
| --- | --- | --- |
| `AGENTS.md` | No hay | Crearlo con los bloques |
| Cómo se llevan las tareas hoy | Hay varios mecanismos | `ROADMAP.md` corto con las unidades vigentes; lo anterior, como archivo |
| `docs/ROADMAP.md` | Ya existe con otro formato (otras columnas, texto alrededor de la tabla) | Ver «ROADMAP.md existente con otro formato», abajo (ADO-9) |
| Rama base y estado del árbol | Árbol sucio o varias ramas viejas | Dejarlo limpio antes de adoptar (la puerta) |
| CI y ramas protegidas | No hay | Guías vecinas |
| Sesiones y contratos con otros proyectos | Hay dependencias | Perfil «con sala» |

### ROADMAP.md existente con otro formato

1. Elegir **dónde vive la narrativa**: moverla a otro archivo (por ejemplo `docs/HISTORIA.md`) y enlazarlo desde la cabecera, o dejarla **debajo** de la tabla estándar.
2. Crear la tabla estándar (`ID`, `Entrega`, `Depende de`, `Estado`) con las unidades vigentes, usando la plantilla.
3. **Retirar la tabla anterior** (o pasarla al archivo de historia). No dejar las dos en `docs/ROADMAP.md`: si conviven, hay dos fuentes del mismo estado (REG-7).
4. Si la narrativa quedó debajo, que no repita estados ni lleve otra tabla con columnas de estado.
5. Hacerlo en el mismo PR de la adopción (ADO-4).

## 5. Cómo verificar que quedó bien

```bash
bash scripts/orquestacion/verificar-adopcion.sh <ruta-del-proyecto>
```

Sin errores, y con las versiones de los bloques iguales a la vigente (`scripts/orquestacion/VERSION`).

El control mira el árbol de trabajo. Lo que leen el panel y la sala es la rama base remota (REG-7), así que, con el PR de adopción ya fusionado y las referencias al día (`git fetch`), correrlo también con `--remoto`: `bash scripts/orquestacion/verificar-adopcion.sh --remoto <ruta-del-proyecto>`. En modo normal, el control avisa si `docs/ROADMAP.md` local difiere del remoto.

| Regla | Cómo se comprueba |
| --- | --- |
| ADO-3 | A mano: lo anterior está como archivo y `docs/ROADMAP.md` lo enlaza |
| ADO-7 | Correr el control (local y `--remoto`); sin errores |
| ADO-9 | A mano: en `docs/ROADMAP.md` hay **una sola tabla con columnas de estado** (la estándar). El control toma la primera tabla con las columnas obligatorias e ignora en silencio las posteriores, así que no detecta una segunda tabla de estado: buscarla con `grep -n "Estado" docs/ROADMAP.md` |

## 6. Problemas conocidos

| Síntoma | Causa | Solución |
| --- | --- | --- |
| Dos sesiones interpretan distinto «completada» | La regla no decía en qué diff se marca | REG-4 y REG-1: figura `Completada` en el diff de su unidad y vale al fusionar |
| Una sesión adopta pero su texto quedó viejo | El bloque se copió antes de una actualización | Marcador de versión y `verificar-adopcion.sh` |
| El proyecto adoptó y sigue sin aparecer en el panel | El `ROADMAP.md` no cumple el formato, o el panel no lo lee todavía | Guía Registro, sección 2; `verificar-adopcion.sh` |
| La orden de adopción no tiene efecto | La sesión estaba ocupada o no la recibió | Exigir `recibido` y buscar rastro en el repositorio antes de reenviar |

## 7. No verificado

- Se probó de forma informal en un conjunto pequeño de proyectos de una misma persona y en pocas horas; no con equipos humanos ni con una adopción formal completa.
- La adopción de un proyecto muy grande (decenas de unidades abiertas) no se probó.
- La lectura del `ROADMAP.md` por un panel concreto todavía no existe.
- `--remoto` se probó con remotos locales (repositorios bare), no contra un alojamiento real, y sin `fetch` automático: si las referencias locales están viejas, valida lo viejo.
- El procedimiento ADO-9 (ROADMAP.md existente con otro formato) no se probó sobre un proyecto real; el control no detecta dos tablas de estado.

## 8. Desviaciones

Anotarlas en `docs/ORQUESTACION.md`.
