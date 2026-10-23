---
id: orquestacion-enlace
title: Orquestación — Enlace entre la sala y los proyectos
last_verified: 2026-10-23
applies_when:
  - existe una sala de Dirección y sesiones de agente en los proyectos que se comunican entre sí
not_when:
  - el proyecto no pertenece a un conjunto con sala (usa solo Registro y Ciclo)
verified_with:
  - mensajería entre sesiones de un agente; usado de forma informal en un conjunto pequeño de proyectos durante pocas horas; sin adopción formal completa (poco tiempo de prueba)
---

# Orquestación — Enlace

> Cómo se avisan la sala y los proyectos, qué mensajes existen y qué hacer cuando la sala está apagada.

Requiere **Dirección** (la sala), y **Ciclo** y **Registro** en los proyectos.

## 1. Cuándo aplica

- **Aplica** si: la sala y los proyectos son sesiones distintas que se envían mensajes.
- **No aplica** si: **no existe sala** (el proyecto es independiente). En ese caso el bloque de Ciclo se instala sin las partes `SALA` y nada de esta guía rige.
- **Caso distinto, la sala existe pero está apagada:** rige el modo sin sala (ENL-2). El proyecto sigue con su `siguiente` local.

## 2. Reglas

| ID | Nivel | Regla | Por qué |
| --- | --- | --- | --- |
| ENL-1 | MUST | **Avisos de ciclo.** Cuando un PR se fusiona y el repositorio no pasa la puerta: `FUSIONADO, NO LISTO` (con el motivo). Cuando la puerta pasa: `LISTO PARA CICLO NUEVO`. La sesión **no vigila por su cuenta**: los evalúa cuando termina con éxito el comando de cierre de la persona **en su ventana**, o cuando la persona le escribe «listo» (si lo corrió en otro lado). Siempre **repite su propia puerta**, aunque el comando haya terminado bien | Un comando puede terminar sin haber dejado el repositorio limpio, y una sesión que no recibe ninguna señal no puede saber que la persona terminó |
| ENL-2 | MUST | **Modo sin sala (paracaídas).** Si la sala no está conectada, la sesión informa en pantalla «sala no conectada: no se verificaron dependencias entre proyectos» y espera el `siguiente` de la persona. Al abrir la sala se hace el barrido de recuperación (DIR-6) | El método no debe depender de que la sala exista en cada momento |
| ENL-3 | MUST | **Tres clases de mensaje de la sala.** (a) **Aviso informativo:** la sesión solo lo lee; se puede mandar en cualquier momento. (b) **Orden de cambio:** escribe archivos; solo cuando el destino pasa su puerta, si no queda en la cola de la sala. (c) **Pase** (`siguiente`): empieza una unidad; solo con la puerta pasada y las dependencias revisadas. Las órdenes y los pases se confirman con `recibido` | Ordenar a un destino sucio mezcla el cambio con su trabajo sin entregar |
| ENL-4 | MUST | **Toda orden y todo pase se confirman** con `recibido`. «Aceptado para entrega» no es una lectura: sin `recibido`, la orden sigue en la cola y se busca rastro en el repositorio destino antes de reenviar | Hubo sesiones obsoletas que aceptaban mensajes en el vacío y un envío que se canceló sin avisar |
| ENL-5 | MUST | **Enmiendas numeradas.** Un cambio que afecta a otro proyecto llega como `Enmienda N`: qué cambia, quién la consume, en qué unidad se incorpora y si *suma* o *rompe* | Sin número y consumidor, nadie sabe si un cambio de contrato ya se absorbió |
| ENL-6 | MUST | **IDs con prefijo** cuando cruzan proyectos (`CATALOGO-C4`, `PRESTAMOS-L9`) | Dos proyectos pueden tener unidades con el mismo ID |
| ENL-7 | SHOULD | Antes de enviar, comprobar que el destino figure como **reciente** en la lista de sesiones | Evita mandar a una sesión que ya no existe |
| ENL-8 | SHOULD | Una orden lleva: ID de la unidad, qué hacer, por qué (la fuente), condiciones, y qué reportar al terminar | La sesión destino no ve el repositorio de la sala |

### Formatos de mensaje

Plantillas completas en `templates/orquestacion/mensajes.md`. Resumen:

```text
LISTO PARA CICLO NUEVO: <rama> == origin/<rama> (<hash>), limpio, sin stash
FUSIONADO, NO LISTO: PR #<n> fusionado; repo no listo: <motivo>
recibido
```

## 3. Alternativas y criterio para elegir

| Opción | Conviene cuando | Costo |
| --- | --- | --- |
| Mensajes entre sesiones (esta guía) | Hay mensajería entre las sesiones del agente | Depende de que la herramienta de mensajería funcione |
| Archivo en el repositorio del proyecto (enmiendas y avisos escritos) | No hay mensajería, o la sala está apagada | Más lento: el destino se entera al leer |
| Ambos | Se quiere velocidad y respaldo | Dos lugares donde mirar |

## 4. Cómo implementarlo

1. Incluir en el bloque Ciclo del `AGENTS.md` de cada proyecto las partes marcadas `SALA`.
2. Escribir en el mapa de la sala (`ENLACES.md`) las dependencias y los contratos.
3. Probar el circuito con un proyecto: unidad fusionada → comando de cierre de la persona → «LISTO» → la sala responde con aviso, orden o pase → el proyecto contesta `recibido`.

## 5. Cómo verificar que quedó bien

| Regla | Cómo se comprueba |
| --- | --- |
| ENL-1 | Con una unidad fusionada, la sesión avisa «FUSIONADO, NO LISTO» si el repositorio sigue en la rama fusionada, y «LISTO PARA CICLO NUEVO» después del cierre |
| ENL-2 | Con la sala apagada, la sesión muestra el aviso de modo sin sala y no se queda esperando |
| ENL-3, ENL-4 | Se manda una orden de cambio a un destino sucio: no se ejecuta y queda en la cola; con el destino limpio, se ejecuta y llega `recibido` |
| ENL-5, ENL-6 | A mano: las enmiendas están numeradas y los IDs que cruzan proyectos llevan prefijo |

## 6. Problemas conocidos

| Síntoma | Causa | Solución |
| --- | --- | --- |
| La orden no tiene efecto | El destino estaba obsoleto o ocupado | ENL-4 y ENL-7 |
| Una orden pisa trabajo sin entregar | Se mandó una orden de cambio sin pasar la puerta del destino | ENL-3 |
| Dos proyectos usan el mismo ID | No hay prefijo | ENL-6 |
| Un contrato cambió y el consumidor no se enteró | No hubo enmienda | ENL-5, y revisar el mapa de contratos |
| La sesión nunca avisa «LISTO» | Nadie le escribió y el comando de cierre se corrió en otra ventana | ENL-1: escribir «listo» a esa sesión |

## 7. No verificado

- Si la herramienta de mensajería de otro agente conserva las mismas garantías: acá solo se probó una.
- El comportamiento con la sala caída durante días.
- Cómo detecta la sesión que un PR se fusionó sin que nadie le escriba: no lo detecta; depende de la señal de la persona (ENL-1).

## 8. Desviaciones

Anotarlas en `docs/ORQUESTACION.md` de la sala y del proyecto.
