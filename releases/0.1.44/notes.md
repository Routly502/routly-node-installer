# Routly 0.1.44 — Cajas NAP, Excel y documentos fiscales

## Mejoras generales para todos los países

- Importación de cajas NAP desde Excel compatible, con revisión de nombre, ubicación, coordenadas, capacidad y detalles. No importa ocupación ni asociaciones de clientes a partir de un simple contador de puertos.
- Puertos numerados y resumen de disponibilidad dentro de la columna Puertos de cada caja.
- Ordenamiento ascendente y descendente por nombre, router, ubicación, coordenadas, cantidad de puertos y detalles.
- Selección de cajas y eliminación por lotes con una sola advertencia. Al confirmar, los servicios quedan sin caja ni puerto NAP; no se eliminan clientes ni servicios.
- El Excel descargable de clientes incluye Caja NAP con el formato «Nombre de caja (Puerto 6)», conservando una línea por servicio.
- La importación de clientes permite revisar esa referencia y asociarla a una caja existente, validando router, capacidad y disponibilidad del puerto. No crea cajas ni inventa asignaciones. Las cajas deben importarse antes que los clientes; un puerto 0 requiere corrección o dejar la referencia vacía.

## Mejoras exclusivas de El Salvador

- Los nuevos cobros con Recibo + Factura o Recibo + CCF solo se registran después de confirmar la certificación del documento fiscal. Un rechazo o una respuesta sin confirmar mantiene el pago pendiente. Solo recibo conserva el cobro normal sin certificación fiscal.
- Historial fiscal en la pestaña Documentos fiscales, con búsqueda y filtros, separado del formulario Registrar pago.
- Diagnósticos más precisos de emisión y consulta del documento original, sin exponer credenciales ni respuestas sensibles y sin emitir de nuevo automáticamente.
- Ajustes de datos del emisor y del receptor, distrito, formatos de DUI según la versión fiscal y campos de Factura y CCF.

## Importante

La certificación de Factura y CCF con Digifact sigue pendiente de confirmación satisfactoria del proveedor en el entorno de pruebas. Esta versión no anuncia resuelto ese problema, no habilita producción fiscal ni modifica por sí sola credenciales, establecimiento, punto de venta o correlativos del ISP.

La condición de certificación previa se aplica a nuevos cobros fiscales de El Salvador; no revierte ni elimina pagos históricos y no convierte los cobros de otros países en cobros fiscales salvadoreños.

Se conservan los datos y archivos propios de cada ISP. Publicar la versión en Routly Control anuncia su disponibilidad; no instala ni reinicia automáticamente los Nodes. Cada administrador del ISP inicia la actualización desde su panel.
