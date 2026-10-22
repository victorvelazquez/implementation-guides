---
id: versioning-and-releases
title: Versionado y releases automáticos
last_verified: 2026-10-22
applies_when:
  - el repositorio está en GitHub
  - los commits pueden seguir Conventional Commits
  - se quiere que versión, tag, changelog y release se calculen solos
not_when:
  - el equipo no quiere adoptar Conventional Commits
  - es un monorepo de librerías con versiones independientes por paquete (ver alternativas)
verified_with:
  - release-please-action v5, tipo de release node, modo manifest
  - un proyecto público con una sola rama principal
  - un monorepo privado con rama de integración y rama de producción, con una sola versión
---

# Versionado y releases automáticos

> La versión, el tag, el changelog y el release salen de los mensajes de los commits. La persona solo decide **cuándo** publicar, mergeando un PR de release.

## 1. Conceptos mínimos

- **SemVer (`MAYOR.MENOR.PARCHE`)**: parche = arreglo sin cambiar el uso; menor = algo nuevo compatible; mayor = rompe algo ya usado. En `0.x` el contrato es débil; la `1.0.0` es la promesa de estabilidad y la decide la persona.
- **Tag vs release**: el *tag* es una etiqueta de git sobre un commit (`v0.0.2`); el *release* es una página de GitHub construida sobre un tag.
- **Conventional Commits**: `tipo(alcance): resumen en imperativo`. El tipo del commit decide la versión.

| Commit | Efecto en la versión |
| --- | --- |
| `fix:` | parche |
| `feat:` | menor |
| `feat!:` o pie `BREAKING CHANGE:` | mayor (en `0.x` con `bump-minor-pre-major`, sube el menor) |
| Cualquier tipo **visible en el changelog** | al menos parche |
| Tipos **ocultos** (`docs`, `chore`...) | ninguno |

## 2. Cuándo aplica

- **Aplica** a proyectos en GitHub que quieren versiones reproducibles sin escribir números a mano.
- **Otros lenguajes**: cambiar `release-type` (`node`, `python`, `simple`, `go`...); la mecánica es la misma. Solo `node` está verificado.
- **No aplica** si el equipo rechaza Conventional Commits o si cada paquete de un monorepo necesita su propia versión (ver sección 4).

## 3. Reglas

| ID | Nivel | Regla | Por qué |
| --- | --- | --- | --- |
| R1 | MUST | Los commits que llegan a la rama de versionado siguen Conventional Commits. | Sin eso no se puede calcular nada. |
| R2 | MUST | No editar a mano la versión de `package.json`, el manifest ni `CHANGELOG.md`. Solo los cambia el PR de release. | La versión escrita a mano se desincroniza del tag. |
| R3 | MUST | Antes de la primera corrida, el manifest, `package.json` y el último tag deben indicar la misma versión actual. | Es el punto de partida del cálculo. |
| R4 | MUST | Con tags ya existentes con formato `vX.Y.Z`, poner `include-component-in-tag: false`. | Por defecto crea `nombre-vX.Y.Z` y deja dos formatos de tag. |
| R5 | MUST | Leer el PR de release completo antes de mergearlo: título, versión, enlace de comparación (`vA...vB`), archivos modificados. | Así se detectaron un tag mal formado y una versión inicial incorrecta. |
| R6 | MUST | Decidir qué tipos de commit son visibles en el changelog. **Todo tipo visible dispara un release.** | Un `docs:` visible abrió un release de parche sin querer. |
| R7 | SHOULD | En `0.x`, usar `bump-minor-pre-major: true` y `bump-patch-for-minor-pre-major: false`. | Un cambio incompatible no salta a `1.0.0`. |
| R8 | SHOULD | Marcar los releases como pre-release (`prerelease: true`) mientras la versión sea `0.x`. | Comunica que aún no es estable; se quita en la `1.0.0`. |
| R9 | SHOULD | Mergear el PR de release con **squash**. | Queda un solo commit con el título que la herramienta reconoce. |
| R10 | SHOULD | Si hay rama de integración y rama de producción, cortar la versión sobre la **rama de integración** (`target-branch`) y promover a producción solo estados ya etiquetados y probados. | Evita devolver a la rama de integración el commit de cada release. |
| R11 | SHOULD | En un monorepo con una sola versión, declarar `"version"` en el `package.json` de la raíz (aunque sea `private`). | La herramienta necesita ese campo para subir la versión. |
| R12 | SHOULD | Verificar la versión vigente de la action antes de escribirla (sección 5). | Evita inventar una versión. |
| R13 | MAY | Guardar un token personal como `RELEASE_PLEASE_TOKEN` para que el CI corra solo en el PR de release. | Evita el clic de aprobación, pero es una credencial que vence. |
| R14 | MAY | Forzar la versión inicial con `release-as` y quitarlo después de mergear el PR de release. | Corrige un primer release incorrecto; si queda, todos los releases siguientes quedan forzados. |

## 4. Alternativas y criterio para elegir

| Opción | Conviene cuando | Costo |
| --- | --- | --- |
| **release-please** (esta guía) | Se quiere una puerta humana: ver la versión y el changelog en un PR antes de publicar. | Un PR de release que mergear; ajustes de la organización y de Actions. |
| semantic-release | Se quiere publicar automáticamente en cada push, sin PR intermedio (típico al publicar paquetes). | No hay revisión humana previa; más configuración y plugins. |
| changesets | Monorepo de librerías con versiones independientes por paquete. | Cada PR lleva un archivo escrito a mano. |
| Manual (`npm version patch && git push --follow-tags && gh release create --generate-notes`) | Proyecto muy pequeño o pocos releases. | Depende de acordarse; la versión puede desincronizarse. |

## 5. Cómo implementarlo

1. Verificar la versión vigente:
   ```bash
   gh api repos/googleapis/release-please-action/releases/latest -q .tag_name
   ```
2. Copiar los archivos de `templates/`:
   - [`release-please.yml`](../templates/release-please.yml) → `.github/workflows/release-please.yml`
   - [`release-please-config.json`](../templates/release-please-config.json) → raíz del repositorio
   - [`release-please-manifest.json`](../templates/release-please-manifest.json) → `.release-please-manifest.json` (con punto) en la raíz
3. Ajustar: `package-name`, la versión del manifest (R3), la rama del workflow y los tipos ocultos (R6). Escribir los JSON con un editor, **no con un heredoc de shell**, que puede comerse las barras invertidas.
4. Validar que los JSON parsean (`node -e "JSON.parse(require('fs').readFileSync('<archivo>','utf8'))"`) y que el formateador del proyecto acepta los archivos nuevos.
5. Permitir que Actions abra PRs (**requiere confirmación de la persona**):
   ```bash
   gh api -X PUT repos/OWNER/REPO/actions/permissions/workflow \
     -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true
   ```
   En un repositorio de **organización**, esa opción puede estar bloqueada por la propia organización y hay que habilitarla allí (hace falta ser *owner*).
6. Subir todo en una rama y abrir un PR. Al mergearlo, la herramienta corre por primera vez.

### Ciclo diario

Cada PR de trabajo se mergea según la guía de ramas. La herramienta mantiene **un solo PR de release** y lo actualiza:

```
Lunes     fix: arreglo A      → se abre el PR de release "0.0.3"
Martes    feat: función B     → el MISMO PR pasa a "0.1.0" y suma B
Miércoles docs: actualizo X   → mismo PR (si docs está oculto, ni aparece)
Jueves    se mergea el PR     → UN tag v0.1.0 y UN release con A y B
```

No hay un release por cada PR. La persona decide cuándo publicar.

## 6. Cómo verificar que quedó bien

- Tras mergear: `gh pr list` debe mostrar el PR `chore(<rama>): release X.Y.Z`.
- Leerlo (R5): el enlace de comparación debe decir `vA...vB` sin prefijo extra.
- Al mergearlo: `gh release list` y `git ls-remote --tags origin` deben mostrar el tag nuevo con el formato esperado, y `package.json` debe tener la versión nueva.

## 7. Problemas conocidos

| Síntoma | Causa | Solución |
| --- | --- | --- |
| El PR de release iba a crear el tag `nombre-v0.0.2` | `include-component-in-tag` es `true` por defecto | `include-component-in-tag: false` (R4). |
| El PR de release pide *Approve workflows to run* | El bot cuenta como colaborador externo si se exige aprobación a todos | Aprobar desde el PR, o usar `RELEASE_PLEASE_TOKEN` (R13). |
| El primer release propuso `1.0.0` desde `0.0.0` | **Causa no confirmada**: no había commits con `!` ni `BREAKING CHANGE` | `release-as` con la versión deseada y quitarlo después (R14). |
| Un commit `docs:` abrió un PR de release | `docs` estaba visible en `changelog-sections`, y todo tipo visible es publicable | `"hidden": true` para ese tipo (R6). |
| El PR de release quedó abierto con solo commits ocultos | Si el PR se queda sin commits publicables, la herramienta **no lo cierra ni lo actualiza** | Cerrarlo a mano, sin mergear. |
| La opción *Allow GitHub Actions to create and approve pull requests* está deshabilitada | En repositorios de organización la bloquea la organización | Habilitarla en los ajustes de Actions de la organización. |
| Un archivo JSON de configuración salió inválido | Un heredoc de shell se comió las barras invertidas de una ruta | Escribir el archivo con un editor y validar el JSON. |
| `package.json` queda con el formato de `engines` reescrito en el PR de release | La herramienta reserializa el JSON | Es cosmético; no cambia el comportamiento. |

## 8. No verificado

- **`feat` → versión menor** (por ejemplo `0.1.0` → `0.2.0`) en el modo con `bump-minor-pre-major`: solo se verificó el cálculo con `fix` (parche) y con un tipo visible de documentación (parche).
- **Por qué el primer release propuso `1.0.0`.**
- **Qué hace la herramienta con la rama del PR de release tras cerrarlo a mano.**
- **Ocultar explícitamente `test`, `chore`, `ci` y `build`**: solo se verificó ocultar `docs`. Los demás se ocultan por defecto según la documentación, pero no se comprobó.
- **El token `RELEASE_PLEASE_TOKEN`** (R13): no se creó; no se sabe cómo se comporta el CI del PR de release con él.
- **Releases en otros lenguajes** (`release-type` distinto de `node`).
- **Qué hace la herramienta con commits de merge** en el historial: funcionó con merge commits, pero no se estudió el caso general.

## 9. Desviaciones

Si un proyecto se aparta de un `MUST` o de un `SHOULD`, anotar en el proyecto qué se cambió, por qué y quién lo decidió.
