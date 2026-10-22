---
id: branching-and-merge
title: Ramas y métodos de merge
last_verified: 2026-10-22
applies_when:
  - el repositorio está en GitHub y los cambios se integran por pull request
  - se quiere decidir la estrategia de ramas o el método de merge de cada PR
not_when:
  - el proyecto ya tiene un flujo de ramas documentado por el equipo (se respeta ese)
verified_with:
  - GitHub Flow en un repositorio público con protección de rama
  - rama de integración y rama de producción en un repositorio privado de una organización
  - merge commit, squash y rebase usados en PRs reales
---

# Ramas y métodos de merge

> Define qué ramas existen, cómo entra el trabajo a cada una y qué método de merge usar según el tipo de PR.

## 1. Cuándo aplica

- **Aplica** al definir o revisar el flujo de trabajo de un repositorio en GitHub.
- **No aplica** si el equipo ya fijó otro flujo por escrito: se sigue ese y se toman los criterios de la sección 3 solo si se pide.

## 2. Reglas

| ID | Nivel | Regla | Por qué |
| --- | --- | --- | --- |
| R1 | MUST | Nada entra a la rama principal sin pasar por un PR. | Es lo que permite que el CI y la revisión actúen antes de integrar. |
| R2 | MUST | Elegir la estrategia más simple que cubra el caso y agregar ramas solo cuando un problema real lo pida. | Cada rama extra es trabajo de sincronización. |
| R3 | MUST | La promoción entre dos ramas de larga vida (`develop` → `main`) se hace con **merge commit**, nunca con squash. | Con squash, Git pierde el vínculo entre las ramas y la siguiente promoción muestra conflictos falsos. |
| R4 | SHOULD | Elegir el método de merge de cada PR con la tabla de la sección 3. | El mensaje que queda en la historia es el que leen el changelog y el versionado. |
| R5 | SHOULD | Usar ramas cortas con nombre `<tipo>/<tema-corto>` (por ejemplo `fix/login-error`) y borrarlas al mergear. | Historia legible y sin ramas muertas. |
| R6 | SHOULD | Proteger la rama principal si el plan de GitHub lo permite (sección 4). | La regla vive en el repositorio y no depende de la memoria. |
| R7 | SHOULD | Configurar el repositorio para ofrecer solo los métodos de merge que se usan. | Evita elegir mal por costumbre. |
| R8 | SHOULD | Que el mensaje del squash sea el título del PR, y que ese título sea un Conventional Commit. | Es lo que lee el versionado automático. |
| R9 | SHOULD | Al borrar una rama local ya mergeada con rebase, comprobar que su contenido está en la rama principal y usar `git branch -D`. | Con rebase los commits cambian de SHA y `-d` la considera no mergeada. |
| R10 | MAY | Crear ramas de mantenimiento (`release/1.x`) solo cuando haya que parchear una versión vieja mientras sigue vigente otra. | Se crean bajo demanda, no por anticipado. |

## 3. Alternativas y criterio para elegir

### Estrategia de ramas

| Estrategia | Ramas | Conviene cuando |
| --- | --- | --- |
| **GitHub Flow** | `main` y ramas cortas con PR. Cada versión es un tag sobre `main`. | Una sola versión viva y poca gente. **Valor por defecto.** |
| **Integración + producción** | `develop` integra y prueba; `main` es lo que usan las personas finales. A `main` solo llegan estados ya probados. | Se quiere un paso consciente y revisable entre "integrado" y "en producción". |
| Git Flow completo | Además `release/*` y `hotfix/*` | Hay varias versiones mantenidas a la vez. Su autor aclaró que no es ideal para entrega continua. |
| Trunk-based | `main` con ramas muy cortas y *feature flags* | Equipos grandes con CI muy fuerte. |

Analogía: GitHub Flow es un puesto callejero con un solo mostrador. Integración + producción es un restaurante con cocina (`develop`) y salón (`main`).

### Método de merge

Con una rama de dos commits `A` y `B`, y `M` ya en la principal:

```
Merge commit:  M ─────────── X     (X = commit de unión)
                \           /
                 A ─── B ───

Squash:        M ─── S             (A y B aplastados en uno)

Rebase:        M ─── A' ─── B'     (copias de A y B, SHAs nuevos)
```

Pregunta de decisión: **¿importan los commits individuales de este PR?**

| Tipo de PR | Método | Por qué |
| --- | --- | --- |
| De trabajo con commits limpios y convencionales | **Rebase** | Cada commit llega intacto y es una entrada del changelog. |
| De trabajo con commits desordenados (`wip`, `typo`) | **Squash** | Esos commits son ruido; el título del PR pasa a ser el mensaje. |
| PR de release que abre un bot | **Squash** | Es un paquete cerrado: un solo commit con el título del PR. |
| Promoción `develop` → `main` | **Merge commit** | Une ramas de larga vida (R3). |

Con un PR de un solo commit, rebase y squash dejan casi lo mismo. Lo que importa es que **el mensaje del commit sea convencional**.

GitHub deja preseleccionado el **último método usado**: mirar el nombre del botón antes de confirmar.

## 4. Cómo implementarlo

1. Elegir la estrategia con la tabla de la sección 3 y anotarla en el repositorio (README o documento de convenciones).
2. Configurar los métodos de merge y el borrado automático de ramas:
   ```bash
   gh api -X PATCH repos/OWNER/REPO \
     -F allow_merge_commit=false -F allow_squash_merge=true -F allow_rebase_merge=true \
     -F delete_branch_on_merge=true -F allow_update_branch=true \
     -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=BLANK
   ```
   Con rama de producción separada hay que dejar `allow_merge_commit=true`, porque la promoción lo necesita.
3. Proteger la rama principal con [`templates/branch-protection.json`](../templates/branch-protection.json), ajustando los nombres de los checks (deben coincidir **exactamente** con `gh pr checks`):
   ```bash
   gh api -X PUT repos/OWNER/REPO/branches/main/protection --input branch-protection.json
   ```
   - `strict`: la rama del PR debe estar al día con la principal.
   - `enforce_admins`: la regla también aplica a la persona dueña del repositorio.
   - `required_approving_review_count: 0` con una sola persona desarrolladora; con 1 se bloquea a sí misma.
   - `required_linear_history` obliga a squash o rebase: **quitarlo** si el repositorio usa merge commit.
4. Si el repositorio es privado y el plan no permite proteger ramas, anotar que la regla R1 depende de la disciplina.
5. Pedir confirmación a la persona antes de cambiar la configuración del repositorio.

## 5. Cómo verificar que quedó bien

- Leer la protección: `gh api repos/OWNER/REPO/branches/main/protection`.
- Leer los métodos: `gh repo view OWNER/REPO --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed,deleteBranchOnMerge`.
- Abrir un PR de prueba: debe exigir los checks y ofrecer solo los métodos esperados.

## 6. Problemas conocidos

| Síntoma | Causa | Solución |
| --- | --- | --- |
| Se mergeó con un método distinto al previsto | GitHub preselecciona el último usado | Revisar el botón antes de confirmar. Con commits convencionales, merge commit sigue funcionando para el versionado, pero deja un commit de unión. |
| `git branch -d` dice que la rama no está mergeada | Con rebase y squash los commits cambian de SHA | Comprobar el contenido (`git diff <rama> <principal>` vacío) y usar `-D`. |
| La API devuelve *Upgrade to GitHub Pro or make this repository public* al consultar protección de rama | Un repositorio privado con plan gratuito no permite protección de ramas ni *rulesets* | Hacer público el repo, cambiar de plan, o asumir que la regla depende de la disciplina. |
| Un check exigido queda en `Expected` para siempre | El nombre exigido no coincide con el del job, o el workflow espera aprobación | Copiar los nombres desde `gh pr checks`; aprobar la ejecución si corresponde. |
| La protección impide mergear un PR hecho por un bot | El bot no dispara el CI con el token por defecto | Ver la guía de versionado y releases. |

## 7. No verificado

- **Que un push directo a la rama protegida sea rechazado**: se leyó la configuración por la API, pero no se probó el rechazo.
- Protección mediante *rulesets* en lugar de protección clásica.
- Cola de merge (*merge queue*).
- Que, tras varias promociones `develop` → `main` con merge commit, no aparezcan conflictos falsos. La primera promoción todavía no se hizo.
- Si `required_linear_history` convive bien con una rama de producción que recibe merge commits.

## 8. Desviaciones

Si un proyecto se aparta de un `MUST` o de un `SHOULD`, anotar en el proyecto qué se cambió, por qué y quién lo decidió.
