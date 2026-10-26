# Routly Node 0.1.25

## Cambios

- Corrección del registro de clientes cuando no se proporciona correo electrónico.
- Carga estable del logo del ISP en el menú y en el inicio de sesión, con caché e invalidación cuando cambia la imagen.
- Configuración de siete horarios diarios editables: tres recordatorios de pago, aviso en pantalla, corte, facturación con mora y respaldo de base de datos.
- Ejecución según la zona horaria del ISP y visualización del resultado o error de cada tarea.
- Generación manual de facturas automáticas pendientes, con confirmación y protección contra duplicados, sin adelantar cortes ni aplicar mora.
- Corrección del período inicial de facturación de servicios pospago existentes al asignarles una plantilla.
- Reserva compartida de tareas entre procesos y protección contra la aplicación repetida de mora.

## Alcance

- Los correos y mensajes requieren los canales de entrega ya configurados.
- El respaldo programado es local y contiene solo la base de datos; no incluye archivos adjuntos ni configuración del servidor.
- Cada ISP inicia su actualización manualmente desde Routly. Publicar el paquete o registrar la versión en Control no inicia una instalación automática.

## Validación

- Integridad SHA-256 e inventario completo del paquete.
- Migración desde el catálogo de la versión 0.1.24 e instalación limpia, en esquemas aislados de desarrollo.
- Arranque de la API extraída en modo Node con Node.js 22 y 24: salud HTTP 200, versión 0.1.25 y rutas Control HTTP 404.
- Generación de PDF con las dependencias y fuentes incluidas en el paquete.
- Estas comprobaciones no sustituyen la activación en una VM Ubuntu del ISP ni una restauración real de su respaldo.
