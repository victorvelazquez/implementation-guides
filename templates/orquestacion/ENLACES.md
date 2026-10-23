# Mapa de enlaces de <conjunto de proyectos>

Archivo de la sala de Dirección. Declara **relaciones**, no estados: el estado vive en el `docs/ROADMAP.md` de cada proyecto y la sala lo lee. Se edita en vivo y se commitea al cerrar la sesión. Última revisión: <fecha>.

## 1. Cómo lo usa la sala

Ver el turno de vigilancia en `guides/orquestacion-direccion.md` (sección 2, «Turno de vigilancia»). Resumen: ante un «LISTO PARA CICLO NUEVO», puerta del proyecto; leer los PR fusionados desde el último barrido; buscar impacto en las secciones 3 y 4; entregar avisos y órdenes (las órdenes de cambio solo a destinos que pasan su puerta; si no, a la cola); devolver `siguiente` al origen si no depende de un ajuste pendiente; registrar el barrido.

## 2. Proyectos

| Prefijo | Proyecto | Repositorio | Base | ROADMAP |
| --- | --- | --- | --- | --- |
| `A` | <proyecto A> | <ruta> | `main` | `docs/ROADMAP.md` |

## 3. Contratos

| Contrato | Archivo | Productor | Consumidores | Qué vigilar |
| --- | --- | --- | --- | --- |
| <nombre> | <ruta del archivo> | `A` | `B`, `C` | <rutas, campos, errores…> |

Criterio **suma / rompe:** agregar un campo, una ruta o un valor es *suma*; quitar, renombrar o cambiar el significado o el tipo es *rompe* y exige una **Enmienda N** a los consumidores.

## 4. Dependencias entre unidades

Solo las que cruzan proyectos o salen del proyecto.

| Unidad | Espera | Tipo |
| --- | --- | --- |
| `B-3` | `A-2` | Otro proyecto |
| `A-5` | La persona decide X | Persona |
| `C-1` | Servidor y DNS | Infraestructura |

Las dependencias que no son proyectos no las resuelve la sala: las **anuncia**.

## 5. Cola de órdenes por proyecto

| Destino | Orden | Estado |
| --- | --- | --- |
| `B` | <ID: qué> | Enviada / Esperando puerta / Confirmada («recibido») |

## 6. Último barrido

| Proyecto | Último PR visto | Fusionado |
| --- | --- | --- |
| `A` | #0 | <fecha> |
