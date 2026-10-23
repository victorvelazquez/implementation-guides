# Ejemplo: cuatro proyectos de una biblioteca vecinal

**Es un ejemplo inventado, no una obligación.** Muestra cómo queda la Orquestación aplicada a un conjunto ficticio, para que quien adopte el método (persona o agente) tenga un modelo concreto. Los nombres, las unidades y las fechas no existen.

## Los proyectos

| Prefijo | Proyecto | Qué es |
| --- | --- | --- |
| `CATALOGO` | Servicio de catálogo | Libros y socios |
| `PRESTAMOS` | Aplicación de mostrador | Préstamos y devoluciones |
| `PORTAL` | Portal público | Consulta del catálogo y reservas de libros |
| `SELLO` | Identidad visual | Tokens de diseño |

La sala de Dirección es un quinto repositorio.

## Un `docs/ROADMAP.md` (el del portal)

```markdown
# Hoja de ruta del portal

**Dónde está:** esqueleto hecho; la cabecera de la página se está construyendo.
**Qué sigue:** P2 (cabecera con datos de ejemplo).
**Qué lo bloquea:** nada por ahora; P7 espera a la aplicación de mostrador.

| ID | Entrega | Resultado visible | Depende de | Estado | Notas | Ficha |
| --- | --- | --- | --- | --- | --- | --- |
| P0 | Documentación y decisión de tecnología | Decisión publicada | — | Completada | PR 5 | — |
| P1 | Esqueleto de la aplicación | Página vacía con la marca | P0 | Completada | PR 9 | — |
| P2 | Cabecera | Nombre, horario y botón principal | P1 | En curso | | odd/tasks/p2.md |
| P3 | Catálogo consultable | Búsqueda por título | P2 | Pendiente | | — |
| P7 | Reservas de libros | Formulario de reserva | P3, PRESTAMOS-L9 | Bloqueada | espera PRESTAMOS-L9 | — |
```

Notar: `Estado` lleva una sola palabra; el número de PR y el motivo del bloqueo van en `Notas`; la dependencia de otro proyecto lleva prefijo y es **informativa** (no la resuelve este archivo: la anuncia la sala). `Completada` figura desde el diff de su unidad y vale cuando el PR se fusiona.

## Un fragmento del mapa de enlaces de la sala

```markdown
## 3. Contratos
| Contrato | Archivo | Productor | Consumidores | Qué vigilar |
| --- | --- | --- | --- | --- |
| Consulta pública de disponibilidad | `docs/CONTRATO-PUBLICO.md` | `PRESTAMOS` | `PORTAL` | Rutas, campos, errores |
| Tokens de diseño | `tokens.json`, `dist/` | `SELLO` | `PRESTAMOS`, `PORTAL` | Nombres y valores |

## 4. Dependencias entre unidades
| Unidad | Espera | Tipo |
| --- | --- | --- |
| `PRESTAMOS-L9` | `CATALOGO-C4` | Otro proyecto |
| `PORTAL-P7` | `PRESTAMOS-L9` | Otro proyecto |
| `PORTAL-P9` | Servidor y DNS | Infraestructura |
```

## Un ciclo, paso a paso

1. La persona entrega y fusiona la unidad `CATALOGO-C4` del servicio de catálogo y corre su comando de cierre en la ventana de esa sesión.
2. La sesión de `CATALOGO` repite su puerta y avisa a la sala: `LISTO PARA CICLO NUEVO: main == origin/main (a1b2c3d), limpio, sin stash`.
3. La sala corre la puerta de `CATALOGO` (LISTO) y lee el PR fusionado. Ve que `PRESTAMOS-L9` esperaba `CATALOGO-C4`.
4. La sala manda a `PRESTAMOS` un **aviso informativo**: «`CATALOGO-C4` está completada; tu `L9` queda destrabada».
5. La sala calcula la próxima unidad de `CATALOGO`; no depende de nada pendiente en otro proyecto; le manda un **pase**: `siguiente`.
6. La sesión de `CATALOGO` responde `recibido` y empieza la unidad nueva.
7. Si `C4` hubiera cambiado el contrato de acceso, el paso 4 sería una **orden de enmienda**, que `PRESTAMOS` ejecutaría solo cuando su repositorio pase la puerta; hasta entonces queda en la cola de la sala.

## Con la sala apagada

La sesión de `CATALOGO` muestra «sala no conectada: no se verificaron dependencias entre proyectos» y espera el `siguiente` de la persona. Al abrir la sala, el barrido de recuperación lee los PR fusionados desde el último registro y manda lo que quedó pendiente.
