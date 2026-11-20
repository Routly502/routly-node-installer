# Routly 0.1.53 — Correlativos fiscales independientes y portal del cliente

## Facturación electrónica

- Contadores separados para Factura (01) y Comprobante de Crédito Fiscal (03), por emisor, ambiente, establecimiento y punto de venta.
- La configuración muestra «Siguiente Factura (01)» y «Siguiente CCF (03)». Al cambiar de serie recupera sus propios valores y bloquea el guardado si no puede consultarlos.
- La actualización conserva el contador anterior como piso de ambas series originales, sin asignar automáticamente números deducidos de documentos externos.
- Se conservan las reservas de documentos pendientes, inciertos y rechazados. Las reservas simultáneas no repiten números y no se permite retroceder por debajo del historial conocido.
- Una corrección permitida por rechazo confirmado reserva en la serie original del documento, aunque se haya cambiado la configuración activa.
- No se modifica, reenvía ni renumera el CCF sin confirmar. DOC-003 y las consultas sin resultado no se consideran prueba de certificación ni de rechazo definitivo.

## Mejoras acumuladas

- Automatizado VIP: métodos exclusivos de texto libre y plantillas Meta, con claves y configuración independientes. Los avisos utilizan el método habilitado y el mismo editor de plantillas.
- El editor admite los parámetros de Automatizado VIP y sus variables de cliente; no se fija un identificador de plantilla para todos los ISP. Los textos y sus identificadores deben corresponder a la configuración real del proveedor.
- El buscador para registrar pagos excluye clientes eliminados.
- Desde las herramientas del cliente se puede abrir una vista de solo consulta de su portal y volver a su perfil administrativo, sin reemplazar la sesión del cliente.
- Configuración de Portal Cliente con logo propio e imágenes publicitarias en el pie del inicio, con rotación cada tres segundos.
- Estadísticas históricas de tráfico del propio cliente y títulos diferenciados entre portal y administración.
- Conserva las correcciones anteriores de correo, saldo a favor por HTTP e historial fiscal.

## Operación segura

- Antes de emitir en una serie que ya se utilizaba en otro sistema, confirmar sus números disponibles con el proveedor y considerar sus reservas y rechazos. El último PDF no garantiza que el número siguiente esté libre.
- La actualización no habilita nuevos proveedores, no envía documentos fiscales ni comunicaciones como parte de la migración, no cambia reglas de MikroTik ni copia identidad o datos de otro ISP.
- La publicación en Control solo anuncia disponibilidad. Cada administrador del ISP inicia la instalación desde su panel, con respaldo y recuperación administrados por el actualizador.
- El estado del CCF previamente sin confirmar requiere aclaración independiente; esta corrección no autoriza repetir su cobro ni emitir un sustituto.

## Verificación del paquete

- Compilación Ubuntu validada, con manifiesto completo y checksum SHA-256.
- 48 pruebas de distribución aprobadas; la corrección fiscal y su formulario también superaron 64 pruebas locales.
- Migraciones comprobadas sobre una base nueva y sobre el paquete 0.1.52 verificado, conservando clientes, servicios, factura y el CCF incierto sintético.
- API extraída del paquete iniciada en Node.js 22.23.5; comprobados guardado y consulta de ambas series, cambio de ambiente y punto, rechazo de retrocesos y generación de PDF.
- No se realizaron emisiones reales a Digifact ni pruebas de entrega desde las cuentas del ISP. La activación en su servidor se confirma después de que el administrador instale la actualización.
