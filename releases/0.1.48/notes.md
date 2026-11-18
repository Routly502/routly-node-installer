# Routly 0.1.48 — Rendimiento, pagos e historial de servicios

## Cambios generales — todos los ISP y países

- Se optimizan las cargas del directorio y los perfiles: cada perfil consulta únicamente sus datos, servicios, facturas y saldos, conservando los permisos de acceso.
- Las secciones se cargan por separado y se evitan esperas de recarga después de un guardado confirmado, sin desmontar el menú ni el logo durante la navegación.
- Al registrar un pago con solo recibo del sistema, la confirmación ya no espera la generación y el envío del correo ni la reactivación en MikroTik. El correo queda en una cola persistente y la reactivación continúa en segundo plano, con reintentos y protección contra pagos duplicados. Un pago guardado no equivale a una reactivación ya confirmada.
- Se corrige la presentación de la fecha de pago para evitar que aparezca el día anterior por diferencias de zona horaria.
- El resumen del cliente muestra fecha y hora de suspensión y retiro cuando se han registrado. Las fechas históricas desconocidas se indican como no registradas; no se inventan ni se reconstruyen.
- Se muestran los routers asociados a los servicios vigentes, incluidos los suspendidos. Un servicio retirado no se presenta como una conexión vigente.
- Retirar un servicio conserva un historial consultable con sus datos de red y dirección, libera la asignación NAP y devuelve los equipos asociados al almacén. Eliminar continúa siendo una acción distinta.
- En «Últimos pagos registrados», pulsar un cliente abre su perfil y conserva la ruta /admin de las instalaciones Ubuntu, evitando el error 404.
- Se retira la etiqueta técnica «active» junto al nombre del cliente. El estado permanece en Resumen → Estado.
- Actualización acumulativa: conserva las funciones y correcciones de las versiones anteriores.

## El Salvador

- No se incorporan cambios exclusivos de país en esta versión.
- El seguimiento con Digifact permanece pendiente. No se anuncia la solución de certificaciones rechazadas o sin confirmar, no se reenvían documentos automáticamente y no se deben repetir cobros para intentar obtener otro documento fiscal.
- La mejora del tiempo de confirmación para «Solo recibo del sistema» no omite las comprobaciones necesarias de una certificación fiscal.

## Actualización

Preparar y alojar el paquete no publica su disponibilidad en Routly Control ni instala actualizaciones. Una vez publicada la versión en Control, cada administrador del ISP decide cuándo actualizar desde Configuración → Actualizaciones.

Las mejoras se verificaron en desarrollo y con datos sintéticos. No representan una garantía de tiempo de respuesta en el servidor de cada ISP.
