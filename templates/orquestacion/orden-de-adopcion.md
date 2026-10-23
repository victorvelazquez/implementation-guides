# Orden de adopción (sala a un proyecto)

Plantilla del mensaje que la sala manda a la sesión de un proyecto para que adopte el método. Reemplazar lo que está entre `<...>`. Es una **orden de cambio**: se manda solo si el proyecto pasa su puerta; si no, queda en la cola del mapa de enlaces.

```text
ORDEN <PREFIJO>-O0 — Adoptar la Orquestación (unidad de DOCUMENTACIÓN)
Soy la sesión de Dirección, que coordina los proyectos por pedido de la persona.
Primero respondé una palabra: «recibido».

Estado de tu repositorio verificado por la sala: <LISTO | motivo>.

Qué hacer, en un solo PR y solo texto:
1. Agregar a AGENTS.md los bloques de Orquestación versión <N>, sin borrar tus reglas actuales
   (si algo ya está definido, prevalece lo más estricto):
   - bloque Registro (obligatorio): [pegar templates/orquestacion/AGENTS-bloque-registro.md]
   - bloque Ciclo (<si el perfil lo incluye>): [pegar templates/orquestacion/AGENTS-bloque-ciclo.md,
     con o sin las partes SALA según el proyecto tenga o no sala]
2. Crear o estandarizar docs/ROADMAP.md con la cabecera de tres líneas y la tabla
   (columnas obligatorias ID, Entrega, Depende de, Estado; Estado = una sola palabra).
   Unidades vigentes: <lista>. No reescribas el historial de otros formatos: dejalo como archivo con un enlace.
3. Crear docs/ORQUESTACION.md con el registro de adopción (templates/orquestacion/registro-de-adopcion.md).
4. Marcar esta unidad Completada en su propio diff.

No toques código ni retomes el producto.
Reportá: archivos, líneas (git diff --stat crudo, LF) y cómo verla.
La persona la entrega con su ciclo.
```
