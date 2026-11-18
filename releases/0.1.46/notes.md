# Routly 0.1.46 — Ciclos de facturación y mejoras generales

## Cambios generales — todos los ISP y países

- Las facturas manuales de servicios permiten elegir y corregir el **ciclo de servicio**, desde el perfil del cliente y desde Finanzas → Facturación.
- Una deuda de octubre puede mostrar **octubre 2026 e inicio 01/10/2026**, aunque el cliente haya sido importado en noviembre. Cambiar solamente la emisión o el vencimiento no cambia el ciclo.
- Se pueden emitir facturas manuales de servicios suspendidos sin activarlos ni modificar su instalación o inicio de facturación. Se conservan las restricciones de facturas pagadas, anuladas, libres o vinculadas a documentos fiscales y la protección contra períodos duplicados.
- En las importaciones de suscriptores existentes, el inicio elegido también se guarda como fecha de instalación. Se completan las instalaciones importadas que no tenían esa fecha utilizando su inicio guardado, sin reemplazar fechas ya registradas.
- El panel distingue clientes registrados y clientes en línea.
- Se retira el campo Código de pago de uso general. No se habilita para ningún país en esta versión.
- Se elimina la función Aviso en pantalla. La preparación del corte de Routly deja de depender del proxy; no reemplaza la configuración de proxy de otros sistemas.
- Los cortes usan reglas y asociaciones propias de Routly. Las identidades de red compartidas o ambiguas se rechazan antes de preparar reglas para evitar afectar a otros servicios.
- Incluye la eliminación local de servicios ya disponible en 0.1.45: no envía órdenes al MikroTik y conserva el cliente, los demás servicios y el historial.

## El Salvador — facturación electrónica

- Se incorpora la selección de Factura electrónica versión 2 y CCF versión 4 para nuevas reservas conforme a la disponibilidad confirmada por Digifact. Los documentos ya reservados conservan su solicitud e identificadores originales.
- No se cambian globalmente los establecimientos ni puntos de venta de los ISP. S001/P003 corresponde únicamente a la cuenta de pruebas indicada por el proveedor.
- **El seguimiento de certificaciones rechazadas o sin confirmar continúa pendiente con Digifact. Esta actualización no anuncia su resolución ni reenvía documentos automáticamente. No repita un cobro para intentar obtener otro documento fiscal.**

## Distribución

Paquete preparado para Ubuntu, pendiente de publicación en Routly Control. Publicar disponibilidad y autorizar una instalación son operaciones separadas. Ningún ISP se actualiza automáticamente al preparar este paquete.
