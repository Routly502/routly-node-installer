# Routly 0.1.27 — directorio de clientes y automatizaciones

- La lista de usuarios muestra las IP actuales de los servicios del cliente, también al buscar y exportar.
- Generación automática de respaldos desactivada temporalmente, incluidos sus reintentos. Se conservan los archivos existentes y los respaldos de seguridad del actualizador.
- Ingresos y gastos recurrentes: se registran los movimientos generados y los errores, sin llenar el log con comprobaciones de cero movimientos.
- Se omiten los resúmenes rutinarios exitosos de avisos de facturas vencidas, recordatorios y suspensión. Se conservan los errores y las acciones reales sobre los servicios.
- Los envíos a clientes, la generación de facturas y los cortes mantienen su funcionamiento.
- Actualización acumulativa, sin cambios nuevos de esquema respecto de 0.1.26. Cada ISP inicia manualmente su actualización desde Routly.
