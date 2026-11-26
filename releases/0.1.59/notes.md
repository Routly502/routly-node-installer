# Routly 0.1.59 — Panel, notificaciones y TV de Astra

## Panel de operadores

- Inicio configurable por tipo de operador y por empleado, respetando permisos y routers autorizados.
- Bloques de clientes, recaudación, tickets e instalaciones con los colores predeterminados y el diseño profesional de Routly.
- Gráficas y comparaciones con datos reales, sin conceder acceso financiero por el solo hecho de entrar al panel.

## Tickets y notificaciones

- Buscador de clientes al crear tickets y retiro del campo redundante de nombre del solicitante.
- Acciones para tomar o subir evidencia desde el dispositivo del técnico.
- El cliente puede consultar la solución registrada y su historial de atención autorizado.
- Notificaciones flotantes para nuevos tickets y respuestas, tanto en operadores como en el portal del cliente.
- Sonido suave con control de silencio guardado en el navegador, protección contra repeticiones y respeto del bloqueo de reproducción automática.
- Se conservan los permisos separados, el alcance por técnico/router y la descripción con evidencia obligatoria para finalizar.

## Portal del cliente

- Correcciones en consumo en vivo, datos históricos y sesiones, manteniendo aislados los datos de cada cliente.
- Edición del perfil y conservación del modo de consulta del operador sin permitir cambios desde esa vista.
- Conserva el logo, colores, publicidad y apariencia elegidos por cada ISP.

## TV de Astra opcional

- Nueva configuración de TV desde Portal Cliente: URL de lista M3U, contenido pegado o archivo M3U, y URL base para referencias relativas.
- TV desactivada por defecto. Un único control permite limitarla a clientes con servicio activo, sin cambiar reglas financieras.
- Catálogo con búsqueda por nombre/número, categorías, logos o distintivos alternativos y reproductor adaptable a escritorio y teléfono.
- Proxy autenticado desde el Node del ISP para manifiestos, variantes, segmentos, claves e inicialización HLS; el navegador no recibe las direcciones internas de Astra.
- Resolución de rutas relativas/anidadas, conservación de query strings, rangos parciales, cancelación al salir y timeouts acotados.
- Desactivar TV o suspender el servicio bloquea las solicitudes nuevas, incluso con enlaces guardados.
- La ruta habitual sigue siendo `/cliente/tv`; el acceso específico solicitado `/clientes/tv` conduce a ella.

## Instalación y conservación

- Versión acumulativa posterior a 0.1.58, con migraciones forward incluidas.
- No contiene bases de datos, archivos, licencias ni credenciales de ningún ISP.
- No cambia automáticamente MikroTik, firewall, VLAN, certificados ni rutas de red.
- Preparar este paquete no crea ni publica una versión en Routly Control y no asigna instalaciones.
- Tras publicar su disponibilidad en Control, cada administrador del ISP decide cuándo actualizar.

## Límite de las comprobaciones

- Las pruebas de Astra utilizan un servidor HTTP y cuentas aislados; no equivalen a reproducir una señal en la LAN física del ISP.
- La compatibilidad física con Safari/iPhone y la reproducción prolongada de señales reales quedan pendientes de validación autorizada.
- En HLS nativo rigen las capacidades del navegador; hls.js ofrece selección de calidad cuando el canal publica variantes.
