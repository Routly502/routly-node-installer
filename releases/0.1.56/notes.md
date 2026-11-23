# Routly 0.1.56 — Estados por servicio y nómina por país

## Directorio de clientes

- Cada IP muestra el estado de su servicio y los filtros distinguen clientes con servicios activos, suspendidos o sin servicios vigentes.
- Un cliente con servicios activos y suspendidos puede encontrarse por ambos filtros, sin reactivar servicios ni cambiar su deuda.

## Empleados

- Teléfono disponible en registro y edición.
- NIT y turnos opcionales, sin bloquear el registro; los turnos proporcionados siguen validándose.
- Tipo de empleado: Planilla o Servicios técnicos para todos los ISP. No se asigna automáticamente a los empleados existentes.

## Nómina mensual

- Descuentos automáticos de Planilla según el país fiscal: Guatemala y El Salvador.
- Resumen de sueldo, descuentos y neto en registro, edición y nómina.
- Cálculo limitado al sueldo mensual: sin pedir acumulados ni configuración anual. El contador gestiona los ajustes fiscales y las obligaciones adicionales.
- El Salvador: ISSS laboral del 3 % con máximo de USD 30, AFP del 7.25 % y tabla mensual de ISR sobre la base correspondiente.
- Guatemala: IGSS laboral del 4.83 % y estimación mensual de ISR con las reglas verificadas para el período. La bonificación de Q250 no se agrega automáticamente ni forma parte del sueldo base registrado.
- Servicios técnicos conserva los ajustes manuales sin aplicar automáticamente los descuentos de Planilla.
- Los períodos cerrados mantienen sus importes históricos. No se recalculan por cambiar el sueldo o el tipo de empleado.

## Pagos adicionales

- El Salvador: bono de vacaciones del 30 % sobre medio sueldo, Aguinaldo por escala y proporcional, y Quincena 25 completa o proporcional para salarios de hasta USD 1,500.
- Vacaciones conserva el sueldo mensual completo y suma únicamente el bono, sin duplicar los 15 días de sueldo.
- Guatemala, solo Planilla: Bono 14 y Aguinaldo completos o proporcionales sobre la base ordinaria promedio confirmada; Aguinaldo con pago completo o cuotas del 50 %.
- Los pagos adicionales se registran manualmente y se suman al neto sin aumentar los descuentos automáticos del sueldo. La ausencia de descuentos automáticos no sustituye la revisión fiscal del contador.

## Actualización

- Incluye las migraciones de tipo de empleado y compatibilidad de nómina, sin inferir contratos ni modificar salarios existentes.
- Conserva los cambios de rendimiento, facturación, portal /cliente y configuración HTTPS de las versiones anteriores.
- Preparar este paquete no publica la versión en Routly Control ni inicia instalaciones.
- Publicar posteriormente en Control anuncia su disponibilidad; cada administrador del ISP decide cuándo actualizar desde Configuración → Actualizaciones.

## Comprobaciones del paquete

- 63 pruebas de distribución aprobadas y comprobaciones de tipos de API y panel web correctas.
- Paquete compilado validado por su manifiesto y por el validador y planificador distribuidos en 0.1.55.
- Migraciones verificadas desde cero y desde 0.1.55, con repetición idempotente y catálogo completo de 106 tablas del Node.
- API extraída iniciada con Node.js 22.23.5; salud y versión correctas, rutas de Control no expuestas.
- Nómina verificada en la API compilada: cálculos de Guatemala y El Salvador, pagos adicionales sin aumentar descuentos, conservación del cierre histórico y generación del recibo PDF.
- No se contactó a proveedores fiscales, de mensajería ni bancarios. No se modificaron servidores ISP.
