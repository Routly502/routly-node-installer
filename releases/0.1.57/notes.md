# Routly 0.1.57 — Nómina organizada y reportes profesionales

## Nómina del mes

- Buscador de empleados y paginación de 10 empleados para evitar listados extensos.
- Totales de salario base, comisiones, horas extra, otros pagos, descuentos y neto a pagar.
- Los totales corresponden a todos los empleados del filtro, no solo a la página visible.
- Las exportaciones PDF y Excel incluyen todo el conjunto filtrado, no solo diez empleados.
- Se conservan los ajustes, cierres, reaperturas y cálculos existentes.

## Historial de nómina

- Vista inicial agrupada por mes, con cantidad de empleados, estado abierto/cerrado y totales.
- Acceso al detalle de cada mes con búsqueda, paginación y totales del filtro.
- Los períodos cerrados continúan disponibles para consulta; cerrar no elimina ni oculta registros.
- Los importes pendientes de cálculo se identifican sin presentarlos como un neto definitivo.

## Recibos y reportes

- Recibos individuales con el logo y nombre del ISP, desglose de ingresos y descuentos, neto destacado y firmas.
- PDF mensual horizontal con identidad del ISP, totales y encabezados repetidos.
- Excel mensual en formato .xlsx real con logo, filtros, encabezados fijos y formato monetario.
- Los reportes utilizan los importes guardados y no cambian las reglas de cálculo de nómina.

## Actualización

- Conserva los cambios y migraciones de las versiones anteriores, sin añadir migraciones de datos para estas mejoras.
- Esta preparación no crea ni publica la versión en Routly Control ni inicia instalaciones en los ISP.
- Después de anunciar la versión en Control, cada administrador del ISP decide cuándo actualizar desde su panel.

## Verificación

- 11 pruebas de reportes, selección, paginación, búsqueda, totales e historial; 5 pruebas de recibos y nómina de la API; 53 pruebas de integridad y compatibilidad de distribución.
- Comprobaciones de tipos del panel web y de la API correctas.
- Validación del paquete con el validador y planificador de la versión anterior.
- Migraciones desde cero y desde 0.1.56, con repetición idempotente y comprobación del catálogo completo del Node.
- Inicio de la API compilada con Node.js 22, consulta del historial abierto/cerrado y generación del recibo PDF sin modificar servidores ISP ni contactar proveedores fiscales.
