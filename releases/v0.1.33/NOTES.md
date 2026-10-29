# Routly 0.1.33 — Servicios de clientes y Torch PPPoE

- Corregido el enlace de las tarjetas de Últimos conectados: tanto ONLINE como OFFLINE abren directamente la pestaña Servicios del cliente, conservando la ruta `/admin` en Ubuntu y sin cambiar el diseño de las tarjetas.
- El enlace Ver todos los usuarios también conserva la ruta base de la instalación.
- El directorio de clientes muestra las direcciones de los distintos servicios, además de sus IP; la búsqueda por dirección considera esas direcciones.
- Torch reconoce los nombres dinámicos PPPoE entre signos `< >`, como `<pppoe-MiltonL>`, y selecciona automáticamente la interfaz correspondiente al usuario del servicio.
- Si RouterOS no devuelve la interfaz PPPoE activa del cliente, Torch muestra el problema y no inicia una captura en la WAN ni en una interfaz de otro servicio.
- Se conserva el inicio automático de Torch al abrir la ventana y el monitoreo continuo hasta detenerlo o cerrar la ventana.

Cada administrador del ISP decide cuándo iniciar la actualización desde Routly. Publicar esta versión en Control no instala la actualización automáticamente.
