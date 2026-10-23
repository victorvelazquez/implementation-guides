---
id: orquestacion-ciclo
title: Orquestación — Ciclo de entrega
last_verified: 2026-10-23
applies_when:
  - un agente implementa y una persona revisa y entrega
  - se quiere que cada unidad nazca de un estado limpio y se cierre con un reporte comparable
not_when:
  - el proyecto lo trabaja una sola persona sin agentes y no necesita un proceso de entrega
verified_with:
  - Git y GitHub CLI; usado de forma informal en un conjunto pequeño de proyectos durante pocas horas; sin adopción formal completa (poco tiempo de prueba)
---

# Orquestación — Ciclo de entrega

> Cómo se construye, se verifica y se entrega una unidad, y cómo se vuelve a un estado limpio para la siguiente.

## 1. Cuándo aplica

- **Aplica** si: hay un agente con sesión en el repositorio y una persona que revisa y entrega.
- **Funciona solo**, sin los otros métodos. Es recomendable junto con **Registro** (del que toma `siguiente` y el `ROADMAP.md`).

## 2. Reglas

### El ciclo

1. **Puerta.** El repositorio está en la rama base, limpio y al día.
2. **Estimar y partir.**
3. **Implementar** (pruebas primero cuando aplique).
4. **Verificar** según el riesgo.
5. **Reportar** a la persona.
6. **Entregar** (la persona: commit, PR, fusión).
7. **Cerrar:** la persona vuelve a la rama base y actualiza; el agente repite su puerta y lo informa.

### Reglas

| ID | Nivel | Regla | Por qué |
| --- | --- | --- | --- |
| CIC-1 | MUST | **Puerta.** Antes del primer archivo de una unidad nueva: (a) estás en la rama base, (b) el árbol está limpio y sin stash, (c) la rama base local es igual a la remota tras `git fetch`. Si falla alguna, **no escribir**: decir qué falta (normalmente volver a la rama base). Solo aplica a **arrancar** una unidad, no a seguir una en curso ni a corregir un PR abierto | Empezar sobre una rama ya fusionada o desactualizada ensucia el ciclo recién cerrado |
| CIC-2 | MUST | **Comandos de la persona.** El agente nunca ejecuta commit, PR ni cambio de rama del flujo; los corre la persona. Si se corrieron por error: no reintentar y avisar | La entrega es la decisión humana; no puede depender de que una protección frene un error |
| CIC-3 | MUST | **Reporte de unidad:** archivos, líneas reales con `git diff --stat` **crudo** (para archivos nuevos: `git ls-files -o --exclude-standard \| xargs wc -l`), finales de línea LF, qué se verificó y cómo verlo. **No usar `git add -N`** para contar | Los finales de línea CRLF pueden hacer que un cambio de unas decenas de líneas parezca de miles; y `git add -N` modifica el índice del repositorio |
| CIC-4 | MUST | **Informar a la persona en pantalla** cuando la unidad está lista y cuando el repositorio vuelve a estar listo para otro ciclo (o qué falta) | La persona no debería tener que adivinar el estado |
| CIC-5 | MUST | Las reglas viven en el `AGENTS.md` del proyecto (bloque con versión), no solo en la memoria de la sesión | La memoria se compacta, se pierde o cambia de sesión |
| CIC-6 | SHOULD | **Tamaño.** Estimar antes de implementar; si el código pasa de 450 líneas, partir. Tope de 600 por PR; solo se supera por pruebas y con nota explícita. Estimar las pruebas de seguridad en unas 6 veces el código. Controlar el tamaño **durante** el trabajo, no solo al final | Una unidad que ya no se puede partir bien cuesta más de revisar que de rehacer |
| CIC-7 | SHOULD | **Verificación según el riesgo** (tabla de abajo). Siempre: pruebas propias, tipos de **todos** los paquetes y CI en verde antes de fusionar | Un cambio en un paquete compartido puede romper el chequeo de tipos de otro y dejar el CI en rojo |
| CIC-8 | SHOULD | Lo que toca la base de datos se prueba contra **una base real**, no solo con simulaciones | Las simulaciones no ven errores del motor real; una prueba contra la base real puede encontrar un defecto que haría fallar la función entera en producción |
| CIC-9 | SHOULD | Lo irreversible o público (publicar, cambiar la configuración del alojamiento, ramas protegidas) lo decide la persona | |
| CIC-10 | MAY | Guía de revisión por lotes para la persona: qué mirar según el tipo de unidad | Ordena el tiempo de revisión |

### Verificación según el riesgo y definición de «terminado»

| Tipo de unidad | Terminada cuando |
| --- | --- |
| Documentación | Enlaces válidos, formato limpio, la persona la leyó |
| Backend | Pruebas propias y de integración con base real; tipos de todos los paquetes; CI verde |
| Base de datos | Migración **aditiva** probada en una base descartable; la comparación de esquema no muestra diferencias nuevas |
| Seguridad, datos, contratos, concurrencia | Lo anterior + **verificación independiente** (otro agente o persona) + una prueba que reproduzca el abuso; en un PR aparte si el riesgo es alto |
| Pantallas | Lo anterior + **visto bueno visual de la persona** en el navegador, con datos |

## 3. Alternativas y criterio para elegir

| Opción | Conviene cuando | Costo |
| --- | --- | --- |
| Esta guía | Agentes con sesión y entrega humana | Una verificación al arrancar cada unidad |
| Entrega automática (el agente hace commit y PR) | Proyectos de bajo riesgo y sin dependencias | Pierde el control humano de la entrega |

## 4. Cómo implementarlo

1. Copiar `templates/orquestacion/AGENTS-bloque-ciclo.md` al final del `AGENTS.md` del proyecto, junto al bloque Registro. Quitar las partes marcadas `SALA` si el proyecto no pertenece a un conjunto con sala.
2. El bloque lleva su versión en el marcador (`orquestacion:ciclo v1.0`): la usa `verificar-adopcion.sh` para detectar proyectos desactualizados.
3. Tener a mano los comandos de flujo de la persona (ver la guía Herramientas).

## 5. Cómo verificar que quedó bien

```bash
bash scripts/orquestacion/puerta-de-ciclo.sh <ruta-del-proyecto>
bash scripts/orquestacion/verificar-adopcion.sh <ruta-del-proyecto>
```

| Regla | Cómo se comprueba |
| --- | --- |
| CIC-1 | `puerta-de-ciclo.sh` devuelve LISTO o NO LISTO con los motivos; la sesión repite los mismos tres controles |
| CIC-2 | A mano: ninguna instrucción del bloque manda al agente a correr esos comandos; en la bitácora no aparecen |
| CIC-3 | En el reporte de cada unidad: figura el `git diff --stat` crudo y el conteo de archivos nuevos |
| CIC-4 | La sesión informó el estado al terminar (revisión de la conversación) |
| CIC-5 | `verificar-adopcion.sh` encuentra el marcador `orquestacion:ciclo` con la versión vigente |

## 6. Problemas conocidos

| Síntoma | Causa | Solución |
| --- | --- | --- |
| Un diff pequeño aparece como miles de líneas | Un ayudante dejó los archivos con CRLF | Normalizar a LF y mirar `git diff --stat` crudo antes de reportar |
| Pasan las pruebas y falla en producción | Las pruebas simulaban la base | CIC-8: una prueba contra base real |
| El ayudante pasa el tope sin frenar | Se midió solo al final | CIC-6: controlar durante el trabajo |
| El CI queda en rojo por otro paquete | Se verificó solo el paquete tocado | CIC-7: tipos de todos los paquetes |
| La sesión empieza sobre una rama ya fusionada | Se dio la orden antes de volver a la rama base | CIC-1 |
| El índice aparece con archivos «añadidos» que nadie añadió | Alguien usó `git add -N` para contar líneas | CIC-3, y `git restore --staged` en los archivos afectados |

## 7. No verificado

- Los umbrales (450 y 600 líneas, factor 6 de pruebas) salieron de pocas horas de uso; ajustarlos con datos propios.
- No se probó en equipos de varias personas revisando a la vez.
- Cómo sabe la sesión que la persona terminó el comando de cierre depende del agente; la guía Enlace lo trata.

## 8. Desviaciones

Anotarlas en `docs/ORQUESTACION.md` del proyecto: qué cambió, por qué y quién lo decidió.
