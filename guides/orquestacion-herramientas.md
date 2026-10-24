---
id: orquestacion-herramientas
title: Orquestación — Herramientas
last_verified: 2026-10-23
applies_when:
  - se adopta cualquiera de los métodos de Orquestación y hay que decidir qué herramientas hacen falta
not_when:
  - el proyecto no adopta ningún método de la familia
verified_with:
  - Windows 11 con Git Bash; las herramientas de sesión son las de un agente concreto (Gentle Shell / Pi)
---

# Orquestación — Herramientas

> Qué herramientas usa el método, cuáles son obligatorias, cuáles se implementan por separado y cuáles ya tienen su propia guía.

Cada herramienta se implementa **individualmente**. Esta guía solo las lista y dice dónde está cómo hacerlo; no las duplica.

## 1. Cuándo aplica

- **Aplica** si: se está eligiendo qué instalar para adoptar un método.
- **No aplica** si: el proyecto ya tiene todo lo de la lista.

## 2. Reglas

| ID | Nivel | Regla | Por qué |
| --- | --- | --- | --- |
| HER-1 | MUST | Tener **Git** instalado y con acceso a los remotos del proyecto | La puerta, el barrido y el estado en vivo leen Git |
| HER-2 | MUST | Si se adopta Dirección o Enlace: una **sesión de agente por repositorio** con **mensajería entre sesiones** | La sala ordena y los proyectos avisan por esa vía |
| HER-3 | SHOULD | Tener los **comandos de flujo de la persona** (volver a la rama base y actualizar, commit, PR): [`flow-skills`](https://github.com/victorvelazquez/flow-skills) para Pi y Gentle Shell, u otros equivalentes | Son el cierre del ciclo (CIC-1, ENL-1) |
| HER-4 | SHOULD | Usar los **scripts de coordinación** de `scripts/orquestacion/`: `puerta-de-ciclo`, `verificar-repos`, `estado-vivo`, `verificar-adopcion`, `adoptar`. Leen `proyectos.conf`, o una ruta suelta | La puerta, el estado y el control de adopción dejan de depender de la memoria de quien los hace |
| HER-5 | SHOULD | Si se usa Gentle Shell con sala: programar la **limpieza del registro de sesiones** (`scripts/orquestacion/limpieza-de-sesiones/`) | Evita que el registro se llene y rompa la mensajería |
| HER-6 | SHOULD | Usar un **panel de estado** como [`repo-panel`](https://github.com/victorvelazquez/repo-panel), o `estado-vivo.sh` si no se quiere un servidor local | Ver en un solo lugar qué entregar y qué sigue |
| HER-7 | SHOULD | Aplicar las **guías vecinas** de este repositorio: CI con GitHub Actions, ramas y métodos de merge, versionado y releases | La puerta y el cierre suponen ramas y CI ordenados |
| HER-8 | SHOULD | Tener una **verificación independiente** disponible (otro agente o una persona sin acceso al razonamiento del autor) | La pide CIC-7 para seguridad, datos, contratos y concurrencia |
| HER-9 | SHOULD | Tener **GitHub CLI** (`gh`) autenticado | Estado de PR en la sala y en `estado-vivo.sh`; sin él esas columnas quedan vacías |

## 3. Alternativas y criterio para elegir

| Necesidad | Opción | Costo |
| --- | --- | --- |
| Visor de estado | `repo-panel`, o `estado-vivo.sh` si no se quiere un servidor local | `repo-panel` pide Node 20+; el script, Bash |
| Comandos de flujo | `flow-skills` u otros comandos propios | Hay que mantenerlos |
| Mensajería | La del agente; o archivos de enmienda en los repositorios | Los archivos son más lentos |

## 4. Cómo implementarlo

### Mapa de herramientas

| Herramienta | Reglas | Dónde está cómo implementarla |
| --- | --- | --- |
| Git, `gh` | HER-1, HER-9 | Instalación oficial; `gh auth login` |
| Sesión de agente y mensajería | HER-2 | Documentación del agente que se use |
| `flow-skills` | HER-3 | Su README |
| Scripts de coordinación | HER-4 | `scripts/orquestacion/` y `proyectos.conf.example` |
| Limpieza del registro de sesiones | HER-5 | `scripts/orquestacion/limpieza-de-sesiones/LEEME.md` (solo Gentle Shell en Windows) |
| `repo-panel` | HER-6 | Su README; el contrato del `ROADMAP.md` está en la guía Registro |
| CI, ramas, versionado | HER-7 | `guides/ci-github-actions.md`, `guides/branching-and-merge.md`, `guides/versioning-and-releases.md` |

### Pasos

1. Instalar HER-1.
2. Elegir un método y, para cada herramienta que pida, seguir el enlace del mapa.
3. Probar cada herramienta sola antes de integrarla: `puerta-de-ciclo.sh` en un repositorio; `estado-vivo.sh` con dos.

## 5. Cómo verificar que quedó bien

```bash
git --version && gh auth status
bash scripts/orquestacion/puerta-de-ciclo.sh <ruta-del-proyecto>
bash scripts/orquestacion/pruebas/probar.sh
```

Las pruebas de regresión de los scripts deben pasar todas.

## 6. Problemas conocidos

| Síntoma | Causa | Solución |
| --- | --- | --- |
| El agente no puede listar sesiones («descubrimiento no disponible») | El registro de sesiones superó su límite por acumulación de sesiones muertas | HER-5 |
| Los scripts no encuentran los proyectos | `proyectos.conf` con rutas equivocadas o BOM | Revisar las rutas contra `RAIZ_PROYECTOS`; los scripts toleran BOM y CRLF |
| El panel no muestra tareas | El `ROADMAP.md` no cumple el formato | `verificar-adopcion.sh` |

## 7. No verificado

- Los scripts se probaron en Windows con Git Bash; en Linux o macOS deberían funcionar, pero no se verificó.
- HER-5 es específico de un agente concreto; con otro hay que adaptar la lógica de «sesión viva».
- `gh` real contra el alojamiento: las pruebas de regresión no lo cubren.

## 8. Desviaciones

Anotarlas en `docs/ORQUESTACION.md`.
