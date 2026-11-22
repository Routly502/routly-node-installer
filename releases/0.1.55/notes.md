# Routly 0.1.55 — Navegación más ligera y portal /cliente

## Rendimiento

- Clientes y Registrar pagos cargan las herramientas opcionales cuando se necesitan, en lugar de descargarlas todas al abrir la pantalla.
- La carga de gráficos, importadores, documentos y recursos PDF se difiere sin cambiar los cálculos de deuda, los pagos ni sus actualizaciones.
- El mapa usa una consulta ligera de clientes y servicios. Conserva ubicaciones, filtros, enlaces NAP, permisos por router y estados de conexión.
- La configuración compartida de Nginx habilita compresión JSON para HTTP y HTTPS, sin añadir caché de saldos o facturas.
- La mejora real se debe medir en cada ISP después de instalar. Las reducciones de datos observadas en pruebas no equivalen a un porcentaje garantizado de velocidad.

## Portal del cliente

- La ruta del portal es /cliente y el acceso es /cliente/login, para todos los ISP, independientemente del país fiscal.
- No se conserva un alias ni una redirección desde /clientes. Actualiza los enlaces externos que todavía usen la ruta anterior.
- La administración conserva /admin.

## Operación

- Se conservan los cambios de facturación y continuidad de cobros incluidos en 0.1.54.
- Los certificados y el sitio HTTPS local permanecen separados del sitio HTTP administrado por el paquete. Los sitios creados con el asistente de Routly comparten la configuración de rutas y compresión de la versión activa.
- Un sitio HTTPS personalizado debe revisarse por separado; no se sobrescriben sus ajustes.
- Publicar esta versión en Control anuncia su disponibilidad. Cada administrador del ISP inicia la actualización desde Configuración → Actualizaciones.
- Este paquete no cambia por sí solo el DNS, las reglas del MikroTik ni activa certificados.

## Comprobaciones

- Compilación web de producción y API completadas; archivo validado por su manifiesto y por el validador distribuido en 0.1.54.
- 20 pruebas de distribución aprobadas, incluidas las rutas del portal y la configuración compartida HTTP/HTTPS.
- API extraída iniciada con Node.js 22.23.5; comprobados salud, versión, bloqueo de rutas centrales de Control y acceso autenticado a la consulta ligera del mapa.
- Migraciones verificadas en bases desechables, desde cero y desde 0.1.54, incluyendo repetición idempotente, catálogo completo del Node, conservación del historial fiscal y generación de PDF.
- No se enviaron documentos a Digifact ni mensajes a proveedores. Estas comprobaciones no sustituyen la confirmación posterior en cada servidor ISP.
