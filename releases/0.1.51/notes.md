# Routly 0.1.51 — Saldo a favor en HTTP y facturación electrónica

## Corrección prioritaria: Agregar saldo

- Corrige el guardado de ajustes manuales cuando Routly se abre desde una IP local por HTTP.
- El identificador del ajuste ya no depende de una función exclusiva de contextos seguros. Se conserva aleatoriedad criptográfica y la protección contra duplicados.
- Un importe negativo crea saldo a favor y uno positivo registra deuda pendiente, sin movimiento de caja.
- Los reintentos del mismo importe y descripción conservan la clave de operación. Los errores de preparación o del servidor se muestran en la ventana.
- No modifica ni vuelve a crear saldos ya registrados. La corrección entra en efecto en cada ISP al instalar esta versión.

## Facturación electrónica

- Nueva sección en Finanzas, separada de la facturación interna de Routly.
- Lista de documentos certificados y con pago confirmado, según el país configurado. La integración fiscal disponible en esta versión corresponde a El Salvador mediante Digifact.
- IVA a la izquierda del monto y resumen por Factura, Crédito Fiscal y Totales, calculado sobre todos los resultados filtrados.
- Exportación a Excel real (.xlsx) y PDF con todos los resultados coincidentes y su resumen, no solo la página visible. Excel contiene hojas separadas y PDF incluye encabezados y numeración de páginas.
- Los importes fiscales se obtienen del documento emitido, no de cambios posteriores en la factura interna.
- Los rechazos, intentos y operaciones pendientes permanecen en el historial operativo y en el perfil del cliente.

## El Salvador: Factura electrónica y Crédito Fiscal

- Ajustes de compatibilidad del envío a Digifact para Factura electrónica (01) y CCF (03).
- Corregir documentos rechazados conserva los intentos anteriores y prepara identificadores nuevos. Los estados inciertos se consultan antes de repetir una emisión.
- El cobro fiscal se confirma después de certificar. El número de control DTE aparece como número legal del pago cuando existe un documento emitido.
- Pestaña Documentos fiscales junto a Facturas en el perfil del cliente, con su historial y descargas.
- Las certificaciones comprobadas en el preview corresponden al ambiente de pruebas; no equivalen a certificaciones productivas.

## Directorio de clientes

- 15 usuarios por página inicialmente, con opciones 30, 50 o Todos.
- Filtros Router y Ubicación, combinables con estado y búsqueda, sin filtro de Operador.
- Usa asociaciones actuales de los servicios y no considera los retirados como conexiones actuales. No combina el router de un servicio con la ubicación de otro.
- El selector de cantidad aparece antes del filtro de estado. Las exportaciones incluyen todos los resultados filtrados.
- Facturación electrónica también abre con 15 registros por página.

## Portal de clientes y publicación

- Incluye los archivos y rutas del portal de clientes. Conserva el acceso con ID y contraseña del perfil y la contraseña visible para el ISP.
- El acceso del portal en el servidor real del ISP requiere validación después de instalar. No configura automáticamente un dominio público ni confirma que ya esté instalado en ese servidor.
- Versión acumulativa. No recalcula facturas existentes ni traslada datos, identidad, licencia o credenciales entre instalaciones.
- Sustituye la preparación 0.1.50, que no incluye la corrección de Agregar saldo. No publicar 0.1.50 en Control.
- Publicar disponibilidad en Control no instala automáticamente la actualización: cada administrador del ISP decide cuándo actualizar desde su panel.
