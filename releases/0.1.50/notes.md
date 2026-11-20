# Routly 0.1.50 — Facturación electrónica y filtros de clientes

## Facturación electrónica

- Nueva sección en Finanzas, separada de la facturación interna de Routly.
- Lista de documentos certificados y con pago confirmado, según el país configurado. La integración fiscal disponible en esta versión corresponde a El Salvador mediante Digifact.
- IVA a la izquierda del monto y resumen por Factura, Crédito Fiscal y Totales, calculado sobre todos los resultados filtrados.
- Exportación del listado a Excel real (.xlsx) y PDF. Incluye todos los resultados coincidentes, no solo la página visible, y el resumen de cantidades, IVA e importes.
- El archivo Excel contiene hojas separadas de documentos y resumen. El PDF incluye encabezados y numeración de páginas.
- Los importes fiscales se obtienen del documento emitido, no de cambios posteriores en la factura interna.
- Los rechazos, intentos y operaciones pendientes permanecen en el historial operativo y en el perfil del cliente; no se presentan como documentos certificados.

## El Salvador: Factura electrónica y Crédito Fiscal

- Ajustes de compatibilidad del envío a Digifact para Factura electrónica (01) y CCF (03).
- La corrección de documentos rechazados conserva los intentos anteriores y prepara identificadores nuevos; no reutiliza una generación rechazada.
- Se conservan los estados inciertos para consultar el resultado antes de repetir una emisión. Un rechazo no se presenta como pago confirmado.
- El número de control DTE se muestra en el número legal de los pagos cuando existe un documento emitido.
- Pestaña Documentos fiscales junto a Facturas en el perfil del cliente, con su historial y las descargas disponibles.
- Las comprobaciones de certificación realizadas en el preview corresponden al ambiente de pruebas. No equivalen a certificaciones productivas ni sustituyen la configuración fiscal de cada ISP.

## Directorio de clientes

- Vista inicial de 15 usuarios por página; permite elegir 30, 50 o Todos.
- Filtros Router y Ubicación, combinables con estado y búsqueda. No se agrega filtro de Operador.
- Se usan asociaciones actuales de los servicios; un servicio retirado no se considera una conexión actual. Al combinar router y ubicación no se mezclan servicios diferentes.
- El selector de cantidad aparece antes del filtro de estado de usuarios.
- Las exportaciones conservan todos los resultados filtrados, independientemente de la página visible.
- Facturación electrónica también abre con 15 registros por página.

## Portal de clientes y alcance de instalación

- Incluye los archivos y las rutas del portal de clientes incorporados desde la versión anterior. Se conserva el acceso mediante ID y contraseña del perfil y la contraseña visible para el ISP.
- El acceso del portal en el servidor real del ISP sigue requiriendo validación después de instalar la actualización. No se configura automáticamente un dominio público ni se afirma que el portal ya esté instalado en ese servidor.

## Publicación

Versión acumulativa. No se recalculan facturas existentes ni se trasladan datos, identidad, licencia o credenciales entre instalaciones. Publicar la disponibilidad en Routly Control no inicia la instalación: cada administrador del ISP decide cuándo actualizar desde su panel.
