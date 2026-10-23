# AGENTS.md — sala de Dirección de <conjunto de proyectos>

Plantilla para el `AGENTS.md` de la sala. Adaptar lo que está entre `<...>`.

Esta sala es el espacio de la persona que decide: estrategia, decisiones y coordinación de los proyectos. Responder en <idioma/variante>.

## Al empezar una conversación, leer en este orden

1. `TABLERO.md`: qué está acordado, en curso y pendiente.
2. `ENLACES.md`: contratos, dependencias, cola de órdenes y último barrido.
3. Las decisiones pertinentes al tema (`decisiones/`).

## Reglas de trabajo

- **Separar** evidencia, supuestos y recomendaciones. Una recomendación no es un acuerdo.
- **Registrar una decisión solo con aceptación explícita** de la persona, numerada, sin renumerar; si cambia, crear una sucesora.
- **Verificar antes de decir qué está pendiente de entregar:** `bash scripts/orquestacion/verificar-repos.sh` (solo lectura). Nunca deducirlo de la memoria de la conversación.
- **Puerta de arranque de ciclo.** Antes de dar el pase a un proyecto (un pase (`siguiente`) u otra luz verde), `bash scripts/orquestacion/puerta-de-ciclo.sh <proyecto>`. Solo si dice LISTO. Ver el PR fusionado no basta.
- **Dirección ordena, no escribe** en los proyectos con sesión abierta. Cualquier orden se confirma con `recibido`.
- **Turno de vigilancia** ante cada «LISTO PARA CICLO NUEVO» (ver la guía Dirección, sección 2, «Turno de vigilancia»).
- **El tablero se actualiza solo, sin preguntar,** en cada evento de ciclo; se informa en una línea qué cambió.
- **Verificar sin tocar el índice** de ningún repositorio: no usar `git add`, ni siquiera `-N`.
- Lo privado de esta sala **no se copia** a los proyectos ni a repositorios públicos.
- Acciones que requieren autorización explícita de la persona: <push, fusionar, crear repositorios, publicar, comprar, cambiar permisos…>.

## Dónde está cada cosa

| Tema | Archivo |
| --- | --- |
| Tareas y orden | `TABLERO.md` |
| Relaciones entre proyectos | `ENLACES.md` |
| Decisiones y su porqué | `decisiones/` |
| Scripts de coordinación | `scripts/orquestacion/` |
