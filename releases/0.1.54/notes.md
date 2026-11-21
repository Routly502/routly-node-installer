# Routly 0.1.54 — Continuidad de cobros y ajustes de configuración

## Facturación electrónica

- Credenciales de Digifact a la izquierda y emisión de documentos fiscales a la derecha en escritorio; en pantallas pequeñas se apilan para conservar todos los campos.
- Cada sección mantiene su propio botón de guardar. Guardar credenciales no guarda la configuración de emisión ni viceversa.
- El paquete del ISP muestra únicamente Producción en ambas secciones. Pruebas se conserva en el preview de desarrollo.
- Las credenciales de Pruebas no se copian a Producción. Si la emisión anterior estaba configurada en Pruebas, se solicita revisar y guardar Producción; sus correlativos se consultan en su propia serie.
- Reemplazo manual de un intento fiscal no certificado, con confirmación del operador, motivo e historial del intento anterior. El nuevo intento reserva otro identificador y correlativo sin borrar las reservas anteriores.
- Alternativa para registrar el pago y entregar un recibo no fiscal cuando la certificación no se confirma. Una certificación posterior conserva el pago ya registrado y no lo duplica.
- Se conserva la separación de correlativos de Factura (01) y CCF (03), sus reservas y el historial fiscal.

## Automatizado VIP

- Se conservan literalmente las etiquetas y los identificadores configurados por el ISP, incluso las etiquetas que contienen llaves.
- Routly sustituye únicamente los valores de las variables y conserva el mismo editor para texto libre y plantillas Meta.
- Los avisos de emisores y routers admiten el nombre, la IP del equipo y la fecha del evento original.
- Se mantiene el envío mediante la API key del método habilitado, sin activar ambos métodos ni modificar las plantillas guardadas durante la actualización.

## Portal y formularios

- La caja del logo del portal es transparente, sin el fondo blanco anterior.
- La carga de nuevos logos del portal requiere PNG y conserva la transparencia. Los banners siguen aceptando PNG y JPEG.
- El formulario de empleados identifica los campos inválidos para facilitar su corrección.

## Comprobaciones y operación

- Formularios fiscales verificados con 29 pruebas locales, incluidos el guardado independiente, los correlativos por serie y la ausencia de Pruebas en el modo de producción.
- Paquete validado con manifiesto y SHA-256; 52 pruebas de distribución aprobadas.
- API extraída iniciada en Node.js 22.23.5. Comprobadas migraciones nuevas e instalación actualizada desde 0.1.53 en bases desechables, el catálogo de tablas, las dos series fiscales y la generación de PDF.
- Las verificaciones no certifican documentos en Digifact ni envían mensajes reales. La instalación en un ISP se confirma después de que su administrador actualice.
- Cargar el paquete en Control no instala la actualización. Publicar la versión anuncia disponibilidad; cada ISP inicia la actualización desde su panel.
