# Routly 0.1.60 — NetFlow y auditoría de conexiones

## Colector NetFlow

- Recepción y procesamiento de NetFlow v5 en un worker separado de la API, con inserciones por lotes y concurrencia acotada.
- Cola acotada para absorber ráfagas; contadores de recepción, procesamiento, descarte y saturación para diagnosticar pérdidas.
- Una captura defectuosa no descarta los demás paquetes válidos de su lote.
- Conserva la identificación por exportador, cliente, servicio y router, y la protección contra registros repetidos.
- No activa Traffic Flow ni cambia su configuración automáticamente en MikroTik.

## Estadísticas del cliente

- Desglose diario del rango Desde/Hasta con tiempo conectado observado, descarga, subida, sesiones y confirmaciones.
- Estados diferenciados: Con tráfico, Conectado sin flujos y Sin registro de conexión.
- Selección de un día para consultar sus sesiones y eventos sin perder los totales del rango.
- Línea de actividad de 24 horas con detalles por tramo y adaptación a la zona horaria del ISP.
- Historial de conexiones, desconexiones, reconexiones y huecos de observación, con filtro de solo cortes.
- Los servicios simultáneos no duplican el tiempo conectado del cliente.
- Mejor asociación de flujos largos con sesiones compatibles sin contabilizar el mismo flujo en dos sesiones.
- Mantiene los colores predeterminados y el diseño profesional de Routly.

## Observación periódica del router

- Consulta ligera independiente de la sincronización completa de inventario, sin repetir importaciones ni lanzar un ping por cliente.
- Selector Historial por router: 30, 60, 120 o 300 segundos; 60 segundos por defecto.
- Exclusión de ejecuciones solapadas y concurrencia acotada entre routers.
- Las fallas al consultar el router no generan cortes ficticios para sus clientes.
- En IP/ARP, una entrada ausente, incierta o con otra MAC no demuestra un corte y no cuenta como confirmación positiva.

## Conservación e instalación

- Actualización acumulativa posterior a 0.1.59; incluye una migración nueva y aditiva para el historial.
- Conserva los registros existentes sin inventar confirmaciones ni reconstruir flujos que no se capturaron.
- Las nuevas confirmaciones detalladas comienzan a acumularse después de instalar esta versión.
- No incluye bases de datos, archivos, licencias ni credenciales de ningún ISP.
- No modifica automáticamente MikroTik, firewall, VLAN, destinos de Traffic Flow ni la zona horaria del servidor.
- Preparar el paquete no publica la versión en Routly Control ni asigna instalaciones.
- Una vez publicada su disponibilidad, cada administrador del ISP decide cuándo actualizar desde su panel.

## Límites de las comprobaciones

- Se comprobaron PostgreSQL, UDP y RouterOS simulados, filtros de interfaz y actualizaciones por lotes de 4.000 servicios sintéticos.
- La prueba sintética no garantiza la capacidad sostenida de cualquier servidor ni ausencia de pérdidas bajo cualquier carga.
- La observación registra evidencia periódica: no prueba acceso a Internet ni establece la hora exacta de cada corte.
- Un hueco sin observación no debe interpretarse como un corte confirmado.
- No se realizó una prueba física en los MikroTik del ISP ni una revisión visual de la nueva pantalla con sesión iniciada.
