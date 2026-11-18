# Routly 0.1.49 — Prorrateo, impuestos y facturas libres

## Cambios generales — todos los ISP y países

- El prorrateo de la primera factura incluye el día de instalación y el último día del período. No se redondea primero la tarifa diaria.
- El inicio de la primera cobertura prorrateada corresponde al día efectivo de instalación, no necesariamente al primer día del mes.
- En los servicios asociados a un plan con impuesto, las nuevas facturas separan la base y el impuesto a partir del precio mensual acordado del servicio, sin volver a sumar el impuesto sobre un total que ya lo incluye. Se conserva el precio negociado del cliente.
- El desglose se aplica a la vista previa y a las nuevas facturas de servicios individuales, agrupadas y automáticas. Los servicios sin impuesto de plan conservan el comportamiento de impuestos de su plantilla, y las partidas adicionales conservan sus tasas propias.
- Ejemplo de un mes de 30 días: instalación el día 12, hasta el 30 inclusive, con base mensual de 20.00 e impuesto del 13 %: 19 días, base 12.67, impuesto 1.65 y total 14.32.
- Se retiran el selector «Ciclo de servicio» y su aviso de los formularios de creación y edición, tanto en el perfil del cliente como en Facturación. El período de creación vuelve a calcularse automáticamente. Editar partidas, emisión o vencimiento no cambia el período guardado de una factura existente.
- En una nueva factura libre, el vencimiento inicia con la fecha local de hoy y permanece independiente de la fecha de emisión. Se puede cambiar manualmente y se guarda el valor elegido. Al abrir otra factura libre, vuelve a iniciar en el día actual.
- No se recalculan ni modifican facturas ya emitidas. No se cambian por esta corrección los precios acordados de los servicios ni el estado de los clientes.

## Actualización acumulativa

Incluye las mejoras anteriores de cargas del directorio y perfiles, confirmación de pagos con solo recibo sin esperar al correo o a MikroTik, fecha y hora de suspensión/retiro, routers de servicios vigentes, historial de servicios retirados, enlaces del panel al perfil del cliente bajo /admin y retirada de la etiqueta técnica active junto al nombre.

Un pago guardado no equivale a una reactivación en MikroTik ya confirmada. Las mejoras de rendimiento no garantizan un tiempo de respuesta concreto en cada servidor de ISP.

## El Salvador

- El desglose respeta el porcentaje configurado en el plan; el 13 % del ejemplo no se impone a otros países o planes.
- Digifact continúa pendiente de seguimiento. Esta versión no anuncia la solución de certificaciones rechazadas o sin confirmar, no reenvía documentos automáticamente y no requiere repetir cobros.
- La mejora de «Solo recibo del sistema» no omite los controles necesarios de una certificación fiscal.

## Distribución

Publicar disponibilidad en Routly Control no instala la actualización automáticamente. Cada administrador del ISP inicia la actualización desde Configuración → Actualizaciones.

Se entrega un paquete nuevo e inmutable; no sustituye los archivos de la versión 0.1.48. Las verificaciones se realizan con datos sintéticos, sin cobros reales, certificaciones, envíos externos ni cambios en los routers de los ISP.
