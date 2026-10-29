# Routly 0.1.32 — NetFlow y tráfico en vivo

- El colector integrado en Routly Ubuntu recibe y decodifica NetFlow v5 por UDP 9996, sin instalar un colector aparte.
- Relaciona las IP de origen y destino con los servicios de los clientes y acumula los bytes de bajada y subida por hora para las estadísticas.
- Las gráficas y los totales consultan el consumo acumulado; los destinos se muestran como IP y puerto. Las sesiones de conexión y desconexión siguen separadas de los flujos NetFlow.
- Torch toma la IP del servicio, selecciona la interfaz correspondiente y comienza a mostrar tráfico al abrir la ventana.
- El monitoreo Torch continúa hasta detenerlo o cerrar la ventana, sin corte por duración ni límite de capturas simultáneas.
- Cerrar una captura libera su conexión sin detener las otras capturas abiertas.
- Las tarjetas de clientes en línea y fuera de línea del panel abren directamente los servicios del cliente, sin cambiar su diseño.
- El enlace para ver todos los servicios lleva a la lista de usuarios.
- Cada administrador del ISP decide cuándo iniciar la actualización desde Routly. Publicar esta versión no instala la actualización automáticamente.
