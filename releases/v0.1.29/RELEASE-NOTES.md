Routly 0.1.29 — estadísticas NetFlow y sesiones de clientes

- Colector NetFlow v5 integrado en el Node Ubuntu de Routly; no requiere instalar un servicio independiente. Recibe UDP en el puerto 9996.
- Configuración explícita de Traffic Flow en routers MikroTik y estado de recepción del colector.
- Estadísticas de tráfico por cliente y servicio, con IP y puerto de destino; las sesiones PPPoE/IP se muestran separadas de los flujos.
- Recuperación de facturas automáticas faltantes por período del servicio, sin duplicar facturas ya emitidas. La emisión manual de facturas permanece sin cambios.
- «¿Cómo llegar?» abre Google Maps usando las coordenadas del servicio o, si faltan, las del cliente.
- Migración aditiva para almacenar los flujos de tráfico y las sesiones observadas.
- Actualización voluntaria: cada administrador ISP decide cuándo instalarla desde Routly.
