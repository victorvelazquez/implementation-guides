# Orquestación en implementation-guides

Registro de qué se adoptó y qué se desvió. Lo lee `scripts/orquestacion/verificar-adopcion.sh`.

- **Fecha de adopción:** 2026-10-26
- **Perfil:** proyecto independiente (proyecto existente)
- **Bloque Registro en `AGENTS.md`:** versión 1.0
- **Bloque Ciclo en `AGENTS.md`:** versión 1.0 (sin las regiones `SALA`)
- **Métodos adoptados:** Registro, Ciclo

El control de adopción compara las versiones con las vigentes mirando los marcadores `orquestacion:registro` y `orquestacion:ciclo` de `AGENTS.md`; este registro es para las personas.

## Reglas no adoptadas o cambiadas

Ninguna por ahora.

## Herramientas en uso

| Herramienta | Versión o ruta | Nota |
| --- | --- | --- |
| Git y `gh` | | |
| repo-panel | | Bloque `panel:estado` en `AGENTS.md`; `.panel/` ignorado en `.git/info/exclude` |
