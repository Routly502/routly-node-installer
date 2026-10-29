# Routly 0.1.34 — Tráfico en vivo, conexión de servicios y exportación de usuarios

- Corregido el procesamiento continuo de Torch para mostrar las tasas y los flujos que entrega MikroTik, sin reiniciar la captura entre muestras.
- El tráfico comienza al abrir la ventana y continúa hasta detenerlo o cerrarla. Los valores pequeños se muestran en bit/s o kbit/s, sin redondearlos visualmente a 0 Mbps.
- Se mantiene la selección de la interfaz PPPoE correspondiente al servicio; no se utiliza una interfaz WAN ajena como alternativa.
- Retirado el botón «Gráficos Mikrotik» de Herramientas. Se conserva «Tráfico mikrotik».
- La columna Estado de los servicios muestra ONLINE en verde u OFFLINE en rojo según la última sincronización con MikroTik, separada del estado administrativo Activo/Suspendido.
- Los iconos de los clientes en el mapa usan el estado de conexión de los servicios de cada ubicación. Sin una observación disponible se muestran en gris como «Sin sincronizar».
- El perfil y el mapa consultan periódicamente los estados actualizados. Un cambio de conexión no reinicia el acercamiento ni la posición del mapa.
- Excel y PDF del directorio siguen las 20 columnas del formato «Lista de Usuarios», con los datos de los distintos servicios en líneas separadas.
- Excel se descarga como archivo .xlsx real, conserva identificaciones como texto y muestra correctamente varias líneas por cliente.
- El PDF horizontal incluye el logo y los datos configurados del ISP, repite los encabezados en cada página y conserva los textos completos.
- Ambas exportaciones incluyen todo el listado filtrado, no solo la página visible, y respetan los permisos de acceso a los importes.

Traffic Flow continúa con activación manual por router. El consumo histórico y los destinos requieren que el router exporte NetFlow al colector del servidor; Torch es una captura en vivo independiente.

Cada administrador del ISP decide cuándo iniciar la actualización desde Routly. Publicar esta versión en Control no instala la actualización automáticamente.
