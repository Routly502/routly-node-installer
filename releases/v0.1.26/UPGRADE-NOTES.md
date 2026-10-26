# Routly Node 0.1.26

## Cambios

- El menú lateral y el logo permanecen montados al navegar entre las secciones privadas, evitando el parpadeo causado por volver a crearlos.
- Ruta corregida del logo del ISP en el menú y en el inicio de sesión para instalaciones con la interfaz en `/admin/`, incluidos dispositivos nuevos sin caché.
- Configuración de imágenes reorganizada: logo principal y logo de facturas a la izquierda; icono de pestaña y fondo de inicio de sesión a la derecha. En pantallas pequeñas se apilan.
- Nueva opción para subir, reemplazar o borrar el fondo del inicio de sesión en PNG, hasta 20 MB.
- El fondo cubre toda la pantalla al 25 % de opacidad; el formulario permanece al frente, sin transparencia.
- El fondo es accesible antes de iniciar sesión. Solo los administradores pueden modificarlo y en los Nodes se conserva en el almacenamiento persistente local.

## Alcance

- Actualización acumulativa: conserva las funciones y correcciones de las versiones anteriores.
- No requiere volver a cargar los logos existentes.
- Sin cambios nuevos en el esquema de la base de datos respecto de 0.1.25.
- No instala ni selecciona una imagen de fondo automáticamente. Si no se configura una, conserva el fondo predeterminado.
- Cada ISP inicia manualmente la actualización desde Routly. Registrar la versión en Control no inicia instalaciones automáticas.

## Validación

- Pruebas de navegación persistente, rutas de imágenes con base `/admin/`, configuración de imágenes y capas del inicio de sesión.
- Pruebas HTTP de carga, reemplazo, borrado, lectura pública y permisos de administrador del fondo en modo Node.
- Integridad SHA-256 e inventario completo del paquete.
- Comprobación de instalación limpia y migración desde 0.1.25 en esquemas aislados de desarrollo.
- Arranque de la API extraída con Node.js 22 y 24: salud HTTP 200, versión correcta, rutas Control no disponibles y recursos PDF incluidos.
- Estas comprobaciones no sustituyen la activación en la VM Ubuntu de un ISP ni una restauración real de su respaldo.
