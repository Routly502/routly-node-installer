# Routly 0.1.39 — Datos fiscales y conexión Digifact

- Facturación electrónica en el Routly de cada ISP, determinada por su país fiscal guardado.
- El Salvador: NIT y NRC en Datos de la empresa, facturas y vistas previas de plantillas.
- Guatemala: NIT; Honduras: RTN. El NRC no se muestra fuera de El Salvador.
- Conexión API Digifact para El Salvador, con credenciales independientes para pruebas y producción, cifrado y prueba de autenticación.
- Los certificadores solo aparecen después de completar los datos fiscales de la empresa. No se anuncian proveedores no integrados.
- Corrige la vista previa de las plantillas: usa la identidad real guardada del emisor en lugar de la identificación de ejemplo, sin sustituir los diseños personalizados.

Alcance de Digifact: configuración y autenticación. Esta versión NO certifica, transmite ni anula documentos fiscales, y una conexión exitosa no equivale a una factura electrónica certificada.

Incluye migraciones para NRC y configuración de proveedores. Validado el paquete con el validador y planificador de 0.1.38, migraciones nuevas y de actualización con datos de prueba, arranque con Node.js 22 y generación de un PDF con NIT y NRC.

El administrador del ISP inicia la actualización desde Routly. Preparar este paquete no publica ni asigna la versión en Routly Control y no actualiza automáticamente ningún ISP.
