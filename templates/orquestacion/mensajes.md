# Formatos de mensaje

Todo mensaje a una sesión debe poder entenderse **sin ver el repositorio de quien lo manda**: lleva dentro lo técnico que la sesión necesita, nunca el porqué estratégico.

## Clases de mensaje de la sala a un proyecto

| Clase | Escribe archivos | Cuándo se puede mandar | Se confirma con `recibido` |
| --- | --- | --- | --- |
| **Aviso informativo** | No | En cualquier momento | No hace falta |
| **Orden de cambio** | Sí | Solo si el destino pasa su puerta; si no, queda en la cola de la sala | Sí |
| **Pase** (`siguiente`) | Sí (empieza una unidad) | Solo si el destino pasa su puerta y la sala revisó dependencias | Sí |

## Avisos del proyecto a la sala

```text
LISTO PARA CICLO NUEVO: <rama> == origin/<rama> (<hash>), limpio, sin stash
```

```text
FUSIONADO, NO LISTO: PR #<n> fusionado; repo no listo: <motivo>
```

Se mandan solo después de repetir la puerta. No arrancan la unidad siguiente. La sesión no vigila por su cuenta: los evalúa cuando termina con éxito el comando de cierre de la persona en su ventana, o cuando la persona le escribe «listo».

## Confirmación

```text
recibido
```

«Aceptado para entrega» no es una lectura. Sin `recibido`, la orden sigue en la cola y se busca rastro en el repositorio destino antes de reenviar.

## Aviso informativo

```text
AVISO <ID>: <qué pasó en otro proyecto que te afecta>.
Fuente: <proyecto, PR o archivo>.
Cómo te afecta: <una frase>.
Nada que hacer ahora / se incorpora en <unidad>.
```

## Orden de cambio

```text
ORDEN <ID> — <título>
Qué hacer: <concreto>.
Por qué: <la fuente: contrato, enmienda o decisión>, sin copiar lo privado.
Condiciones: <tamaño, rama, si va en una unidad existente o aparte>.
Reportá: archivos, líneas (git diff --stat crudo, LF), qué verificaste y cómo verlo.
Confirmame con «recibido».
```

## Pase

```text
siguiente
```

o `siguiente <ID>` si la primera pendiente está bloqueada y hay otra libre. Se manda solo después de la puerta de la sala y de revisar dependencias, y se confirma con `recibido`.

## Enmienda a un contrato

```text
Enmienda <N> a <contrato>
Qué cambia: <...>
Suma o rompe: <...>
Quién la consume: <proyectos>
Se incorpora en: <unidad de cada consumidor>
Fecha y quién lo decidió: <...>
```
