# Routly 0.1.43 — Diagnóstico de documentos fiscales

- Distingue consultas sin documentos, errores HTTP, respuestas no reconocidas, confirmaciones incompletas y fallos de comunicación con Digifact.
- Muestra el ambiente, la operación y los códigos técnicos seguros disponibles, sin revelar credenciales, datos del receptor ni respuestas completas del proveedor.
- Conserva el diagnóstico para que continúe visible después de recargar.
- Mantiene la recuperación mediante consulta del documento original: un estado sin confirmar o una búsqueda vacía no autorizan otra emisión.

El pago registrado no se modifica ni se vuelve a cobrar. Esta actualización no activa producción fiscal ni emite documentos por sí sola. No recupera retroactivamente respuestas que las versiones anteriores no conservaron.

Después de actualizar el Node, consultar el estado del documento original para obtener el diagnóstico nuevo.

Conserva los datos y archivos del ISP. Publicar en Routly Control no inicia instalaciones automáticamente; cada administrador del ISP inicia la actualización desde su panel.
