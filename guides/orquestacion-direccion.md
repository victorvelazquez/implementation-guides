---
id: orquestacion-direccion
title: Orquestación — Dirección (sala de coordinación)
last_verified: 2026-10-23
applies_when:
  - hay varios proyectos con dependencias entre sí y se necesita un lugar donde decidir, ordenar y vigilar que no se pisen
not_when:
  - hay un solo proyecto, o varios totalmente independientes (alcanza con Registro y Ciclo en cada uno)
verified_with:
  - Git, GitHub CLI y sesiones de agente con mensajería entre sesiones; usado de forma informal en un conjunto pequeño de proyectos durante pocas horas; sin adopción formal completa (poco tiempo de prueba)
---

# Orquestación — Dirección

> Una sala central que decide junto con la persona, ordena a las sesiones de cada proyecto y vigila que un cambio en uno no pise a otro.

Requiere el método **Registro** en cada proyecto y se complementa con **Enlace** (cómo se hablan la sala y los proyectos) y **Ciclo**.

## 1. Cuándo aplica

- **Aplica** si: hay dos o más proyectos que se consumen entre sí (contratos, dependencias entre unidades).
- **No aplica** si: los proyectos no se tocan. Cada uno puede usar solo Registro y Ciclo.

## 2. Reglas

| ID | Nivel | Regla | Por qué |
| --- | --- | --- | --- |
| DIR-1 | MUST | La sala es **un repositorio propio** con su `AGENTS.md` y un mapa de enlaces `ENLACES.md` (plantilla incluida). Lo privado de la sala **no se copia** a los proyectos | Separa el porqué estratégico de lo técnico que comparten los proyectos |
| DIR-2 | MUST | **Dirección ordena, no escribe** en los proyectos que tienen sesión abierta. Excepción: un proyecto sin sesión y un cambio mínimo autorizado por la persona, una sola vez, por el ciclo normal del repositorio | Un cambio de la sala en el árbol de un proyecto se mezcla con su trabajo sin entregar |
| DIR-3 | MUST | El **mapa de enlaces** declara: proyectos, contratos (archivo, productor, consumidores, qué vigilar), dependencias entre unidades, cola de órdenes y último barrido | Sin un mapa, la vigilancia depende de la memoria de quien la hace |
| DIR-4 | MUST | **Puerta antes de toda orden de cambio o pase:** comprobar la puerta del destino (con `puerta-de-ciclo.sh` o a mano con los mismos tres controles de la regla CIC-1). Ver el PR fusionado en el alojamiento **no alcanza**: el repositorio local puede seguir en la rama fusionada | Dar el pase sin esa comprobación hizo que una sesión escribiera sobre una rama recién cerrada |
| DIR-5 | MUST | **Turno de vigilancia** cada vez que un proyecto avisa «LISTO PARA CICLO NUEVO» (ver abajo) | Es lo que permite que un proyecto avance sin pisar a otro |
| DIR-6 | MUST | **Barrido de recuperación** al abrir la sala: leer los PR fusionados desde el último registro del mapa y enviar las órdenes que quedaron pendientes | La vigilancia se demora cuando la sala está apagada, pero no se pierde |
| DIR-7 | SHOULD | **Tablero curado** (`TABLERO.md`) con decisiones, orden y riesgos; actualizarlo **sin preguntar** en cada evento de ciclo e informar en una línea qué cambió. No copia el estado de las unidades: el estado de las unidades se lee de `origin/<base>:docs/ROADMAP.md`; `estado-vivo.sh` muestra el estado de los repositorios y su salida no se versiona | La persona no debería tener que pedir cada vez que se actualice |
| DIR-8 | SHOULD | Decisiones numeradas en una carpeta, solo con aceptación explícita de la persona, y una sucesora cuando una cambia | Conserva el porqué |
| DIR-9 | SHOULD | **Orden por excepción:** el ritmo normal lo marca el `siguiente` de cada proyecto; la sala interviene cuando cambian prioridades, hay un contrato que cambia o una dependencia entre proyectos | Evita que la sala sea cuello de botella |
| DIR-10 | SHOULD | Plantilla de orden de adopción para sumar un proyecto nuevo | |
| DIR-11 | MAY | Guía de revisión por lotes para la persona | |
| DIR-12 | MAY | Métricas por unidad (inicio, «Lista», «Completada») para estimar plazos con datos | |

**Sobre un tope de unidades en espera:** no hace falta fijarlo de forma explícita. La puerta del método Ciclo ya limita a una unidad abierta por proyecto, así que el máximo de unidades «Listas» sin entregar es la cantidad de proyectos.

### Turno de vigilancia (DIR-5)

Cuando el proyecto **X** avisa «LISTO PARA CICLO NUEVO»:

1. **Puerta de X.** Confirmar que está en la rama base, limpio y al día.
2. **Leer lo nuevo.** Los PR fusionados desde el último barrido y qué unidades de X quedaron `Completada` (leyendo la rama base remota de X).
3. **Impacto.** (a) ¿Alguna unidad completada es dependencia de otro proyecto? (sección «Dependencias» del mapa). (b) ¿El PR tocó un archivo de contrato? (sección «Contratos»). Si lo tocó, juzgar si el cambio **suma** (aviso informativo) o **rompe** (orden de enmienda).
4. **Entrega a los afectados.** Un aviso informativo se manda siempre. Una **orden de cambio** solo si el destino pasa su puerta; si no, queda en la cola del mapa hasta que avise «LISTO». Toda orden se confirma con «recibido».
5. **Devolver el turno a X.** Calcular su próxima unidad (primera `Pendiente` con dependencias `Completada`, propias y del mapa). Si no depende de un ajuste pendiente en otro proyecto, mandarle un pase: `siguiente` o `siguiente <ID>`. Si espera algo, no darle el pase y decirle a la persona en qué proyecto actuar.
6. **Registrar el barrido** en el mapa.

**Reglas de espera:** si una unidad «Lista» sin entregar (la sala lo sabe por el aviso de su sesión o por el estado de Git) es dependencia de otras, la sala **no inicia** las dependientes y avisa «entregá primero la de X». Las dependencias que no son proyectos (la persona, la infraestructura) se **anuncian**, no se resuelven.

## 3. Alternativas y criterio para elegir

| Opción | Conviene cuando | Costo |
| --- | --- | --- |
| Sala con sesión propia (esta guía) | Varios proyectos con contratos entre sí | Una sesión más que mantener |
| Sin sala; cada proyecto con Registro y Ciclo | Proyectos independientes | Nadie vigila los pisados |
| Un tablero humano sin agente | Equipos que ya coordinan por reuniones | Más lento; no escala a agentes |

## 4. Cómo implementarlo

1. Crear el repositorio de la sala (privado si contiene decisiones estratégicas).
2. Copiar a la sala `AGENTS-sala.md` (como `AGENTS.md`), `ENLACES.md` y, si se quiere, `TABLERO.md` y una carpeta de decisiones, desde `templates/orquestacion/`.
3. Copiar `scripts/orquestacion/` y editar `proyectos.conf` con la lista de proyectos.
4. Completar `ENLACES.md`: proyectos, contratos y dependencias que ya se conocen.
5. Abrir la sesión de la sala y enviar a cada proyecto la orden de adopción (`orden-de-adopcion.md`), de a uno, empezando por los que pasan su puerta.

## 5. Cómo verificar que quedó bien

| Regla | Cómo se comprueba |
| --- | --- |
| DIR-1, DIR-3 | La sala tiene `AGENTS.md` y `ENLACES.md`, y el mapa tiene las seis secciones de la plantilla |
| DIR-2 | A mano: el historial de los proyectos no tiene cambios hechos por la sala |
| DIR-4 | `puerta-de-ciclo.sh <proyecto>` se corre antes de cada orden o pase (queda en la conversación de la sala) |
| DIR-5, DIR-6 | Se simula: un proyecto avisa «LISTO» y la sala responde con aviso, orden o pase; se apaga la sala, se fusiona algo y al reabrir el barrido lo encuentra |
| Adopción | `estado-vivo.sh` muestra todos los proyectos; `verificar-adopcion.sh` informa qué proyectos tienen el bloque vigente |

## 6. Problemas conocidos

| Síntoma | Causa | Solución |
| --- | --- | --- |
| Dos sesiones de la sala dan órdenes distintas | Quedó abierta una sesión anterior | Una sola sala viva; cerrar las otras |
| Un mensaje se «aceptó» pero nadie lo leyó | La sesión destino estaba obsoleta | Verificar que figure como reciente y exigir «recibido»; ver la guía Enlace |
| Un envío se cancela sin aviso | Falla o cancelación de la herramienta de mensajes | Comprobar el rastro en el repositorio destino y reenviar |
| La sala no puede escribir ni listar sesiones | Se llenó el registro de sesiones del sistema | La herramienta de limpieza de la guía Herramientas |
| La sala duplica reglas que ya tiene un proyecto | Se copió en vez de apuntar | Dejar en la sala un puntero a la fuente de verdad |

## 7. No verificado

- Juzgar si un cambio «suma» o «rompe» lo hace la sala leyendo el diff: es **criterio, no una regla mecánica** y puede fallar en cambios sutiles.
- Probado con un conjunto pequeño de proyectos; no con decenas.

## 8. Desviaciones

Anotarlas en `docs/ORQUESTACION.md` de la sala.
