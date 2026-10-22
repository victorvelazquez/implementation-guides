---
id: ci-github-actions
title: CI con GitHub Actions
last_verified: 2026-10-22
applies_when:
  - el repositorio está en GitHub
  - el proyecto tiene pruebas que se ejecutan con un solo comando
not_when:
  - el proyecto ya usa otro sistema de CI (GitLab CI, Jenkins, CircleCI)
  - todavía no hay ninguna prueba ni comando de verificación
verified_with:
  - actions/checkout v7 y actions/setup-node v7
  - Node 20 y 22, en ubuntu-latest y windows-latest
  - npm, en un proyecto sin dependencias
---

# CI con GitHub Actions

> Hace que cada cambio propuesto se pruebe solo, antes y después de integrarlo. Es la base de todo lo automático que viene después.

## 1. Cuándo aplica

- **Aplica** si el repositorio está en GitHub y las pruebas se lanzan con un comando (`npm test`, `pnpm test`, `pytest`...).
- **No aplica** si ya hay otro CI en uso: se mantiene ese y se toman de aquí solo los principios (R1 a R3).
- **Sin pruebas todavía:** crear antes al menos una prueba, o limitar el CI a `lint` y `build`. Un CI que no comprueba nada da una falsa seguridad.

## 2. Reglas

| ID | Nivel | Regla | Por qué |
| --- | --- | --- | --- |
| R1 | MUST | Ejecutar el CI en cada pull request y en cada push a la rama de integración. | Antes de integrar se valida el cambio; después, el resultado ya integrado. Las dos corridas son intencionales. |
| R2 | MUST | Declarar `permissions: contents: read` a nivel de workflow; ampliar solo en el job que lo necesite. | Mínimo privilegio: un workflow comprometido no puede escribir. |
| R3 | MUST | El CI solo llama al comando de pruebas definido en el repositorio (por ejemplo `npm test`). | El mismo comando corre en local y en CI. |
| R4 | MUST | Fijar cada action al menos por etiqueta mayor (`@v7`) y **verificar la versión vigente antes de escribirla**. | Las versiones cambian; una inventada rompe el workflow. |
| R5 | SHOULD | Usar una matriz con los sistemas y versiones del lenguaje que el proyecto dice soportar, incluido el mínimo. | Lo que no se prueba no se cumple: un script falló solo en Node 20 y nadie lo había notado. |
| R6 | SHOULD | `fail-fast: false` en la matriz. | Cada combinación informa; una celda en rojo es información aunque las demás pasen. |
| R7 | SHOULD | `concurrency` con `cancel-in-progress: true` en workflows de prueba. No usarlo en workflows de release o despliegue. | Evita gastar minutos en corridas que ya fueron reemplazadas. |
| R8 | SHOULD | `timeout-minutes` en cada job. | Un job colgado no consume minutos sin límite. |
| R9 | SHOULD | Dar nombres estables a los jobs. | La protección de rama exige los checks por nombre exacto; renombrar rompe los checks requeridos. |
| R10 | SHOULD | Evitar en los scripts de prueba construcciones que el runtime mínimo no soporte (por ejemplo patrones glob en `node --test` con Node 20). | Es la causa del fallo real descrito en la sección 6. |
| R11 | SHOULD | Si hay dependencias, activar la caché de `setup-node` e instalar con el comando que respeta el archivo de bloqueo (`npm ci`, `pnpm install --frozen-lockfile`). | Instalaciones reproducibles y más rápidas. |
| R12 | MAY | Incluir Windows o macOS solo si el proyecto debe funcionar ahí. | Cada sistema extra consume minutos. |
| R13 | MAY | Fijar las actions por SHA de commit en proyectos con exigencia de seguridad alta. | Evita que una etiqueta movida cambie el código que se ejecuta. |

## 3. Alternativas y criterio para elegir

| Opción | Conviene cuando | Costo |
| --- | --- | --- |
| **GitHub Actions** (esta guía) | El código está en GitHub y no se quiere mantener infraestructura. | Los minutos de repos privados tienen cuota; según la documentación de GitHub, Windows y macOS cuentan más que Linux (verificar el plan vigente). |
| GitLab CI, CircleCI | El código ya está en esa plataforma o el equipo ya la usa. | Otra herramienta que configurar. |
| Jenkins | Se exige ejecutar en infraestructura propia. | Hay que mantener el servidor. |

En un repositorio **privado** con cuota limitada, conviene reducir la matriz (solo Linux, el runtime mínimo y el vigente).

## 4. Cómo implementarlo

1. Confirmar que el comando de pruebas funciona en local.
2. Verificar las versiones vigentes de las actions:
   ```bash
   gh api repos/actions/checkout/releases/latest -q .tag_name
   gh api repos/actions/setup-node/releases/latest -q .tag_name
   ```
3. Copiar [`templates/ci-node.yml`](../templates/ci-node.yml) a `.github/workflows/ci.yml` y resolver cada línea marcada con `ADAPTAR`.
4. Si el proyecto formatea o valida los archivos de `.github/` (por ejemplo con Prettier), ejecutar esa validación: el workflow nuevo tiene que cumplirla.
5. Subir el workflow **en una rama y abrir un PR**, no directo a la rama principal. El primer PR es la primera corrida del CI.

## 5. Cómo verificar que quedó bien

- En el PR deben aparecer todos los checks de la matriz. Listarlos: `gh pr checks <número>`.
- Todos en verde. Si alguno falla, **leer su log y su motivo antes de modificar nada** (sección 6).
- Tras mergear, comprobar que también corrió en la rama principal: `gh run list --branch <rama> --limit 3`.

## 6. Problemas conocidos

| Síntoma | Causa | Solución |
| --- | --- | --- |
| Todas las celdas fallan en 2 segundos y el job no tiene pasos | La cuenta de GitHub estaba bloqueada por un cobro pendiente. El motivo está en las anotaciones del job: *"account is locked due to a billing issue"*. | Resolver el pago en la configuración de facturación. Leer las anotaciones: `gh api repos/OWNER/REPO/check-runs/<id-del-job>/annotations`. |
| Falla solo una versión del runtime (por ejemplo Node 20) | Un script usa algo que esa versión no soporta: `node --test "test/*.test.js"` no entiende el patrón en Node 20. | Usar `node --test` sin argumentos y dejar que descubra los archivos. |
| Los checks quedan en `Expected — Waiting for status to be reported` y aparece *Approve workflows to run* | El PR lo abrió un bot o un colaborador externo y el repositorio exige aprobación para ejecutar workflows. | Aprobar la ejecución desde el PR. |
| La protección de rama exige un check que nunca aparece | El nombre del check exigido no coincide exactamente con el del job. | Copiar los nombres desde `gh pr checks`. |
| `lint` falla en el workflow nuevo | El proyecto formatea `.github/` y el archivo no cumple su estilo. | Ejecutar el formateador del proyecto sobre el workflow. |

## 7. No verificado

- Caché de dependencias y `pnpm` en monorepos: la receta (R11) se basa en la documentación, no en una prueba propia.
- Servicios en el job (por ejemplo una base de datos con `services:`).
- Runners de macOS.
- Workflows reutilizables (`workflow_call`) para compartir el CI entre repositorios privados.
- El costo real en minutos de la matriz en cuentas privadas.

## 8. Desviaciones

Si un proyecto se aparta de un `MUST` o de un `SHOULD`, anotar en el proyecto qué se cambió, por qué y quién lo decidió.
