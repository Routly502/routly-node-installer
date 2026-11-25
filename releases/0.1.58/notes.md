# Routly 0.1.58 — Accesos por empleado, portal personalizable y atención de tickets

## Empleados y pantalla de inicio

- La selección de routers aparece al inicio del formulario del empleado, junto a su foto, tanto al registrar como al editar.
- Se conserva la elección entre todos los routers y únicamente los seleccionados; no seleccionar ninguno no concede acceso a zonas.
- Inicio configurable por tipo de operador o mediante bloques particulares por empleado.
- Los técnicos y soporte pueden consultar sus tickets asignados; los vendedores pueden consultar las instalaciones que registraron como sus ventas.
- Los datos financieros del inicio no se conceden por el solo hecho de acceder al panel.

## Permisos y consultas de red

- Catálogo de permisos ampliado para los módulos que no aparecían en la configuración del empleado.
- OLT disponible para soporte y técnicos; se mantiene configurable para los demás tipos de operador.
- Consulta del mapa completo para los tipos de operador, incluidas cajas NAP e infraestructura, sin conceder permisos para modificarlas y respetando el alcance autorizado.
- Corrección de la consulta limitada de routers para operadores de cobros, sin darles acceso administrativo a equipos.

## Atención de tickets

- Registro manual de aceptación, llegada, inicio y finalización, con tiempos e historial por atención. No utiliza GPS.
- Permisos independientes para crear, editar, eliminar y cerrar tickets.
- El técnico solo consulta tickets actualmente asignados a su persona, además de las restricciones por router; tampoco accede por enlaces directos a tickets, documentos o evidencias de otros técnicos.
- Crear, editar, eliminar y cerrar no se otorgan automáticamente al técnico; los permisos personalizados ya concedidos se conservan.
- Para finalizar un trabajo se exige descripción y una foto o video de hasta 10 MB. Las evidencias se guardan de forma privada.
- Finalizar deja el ticket Resuelto. Cerrar es una acción separada y, para el operador autorizado, exige haber finalizado la atención actual.
- El administrador conserva la reasignación y el cierre administrativo. Reasignar o reabrir conserva las atenciones anteriores.

## Portal de clientes

- Configuración de color principal y color de acento por ISP, aplicada al acceso y al interior del portal.
- Imagen opcional sobre el fondo de color del acceso, con porcentaje de transparencia configurable e inicial del 60 %.
- Conserva el logo propio del portal, los banners y la identidad de cada ISP.

## Clientes y conservación de datos

- Estado general del cliente coherente con sus servicios: un servicio activo evita presentar como suspendido a todo el cliente por otro servicio suspendido.
- Migración de resúmenes antiguos sin cambiar el estado de los servicios, deudas ni configuración de MikroTik.
- Se mantienen los recibos, reportes PDF/Excel, totales e historial de nómina de la versión anterior.

## Instalación

- Versión acumulativa posterior a 0.1.57, con migraciones para resúmenes de clientes, apariencia del portal, atenciones, inicio por empleado y evidencias.
- El paquete contiene la aplicación compilada y sus migraciones; no incluye la base de datos, archivos, licencias ni credenciales de ningún ISP.
- Esta preparación no crea ni publica la versión en Routly Control y no inicia instalaciones.
- Después de publicar su disponibilidad en Control, cada administrador del ISP decide cuándo actualizar desde su panel.

## Verificación del paquete

- 56 pruebas de integridad, distribución, rutas y compatibilidad de migraciones aprobadas.
- Paquete validado con el validador y planificador incluidos en la versión 0.1.57.
- Migraciones probadas desde una base nueva y desde 0.1.57, con repetición idempotente y comprobación de todas las columnas del catálogo Node.
- API extraída del paquete iniciada con Node.js 22.23.5; comprobados versión, salud y exclusión de las rutas centrales de Control.
- Verificados en la API compilada el guardado de colores y transparencia, inicio del técnico, aislamiento entre técnicos, permisos separados, finalización con evidencia privada y cierre autorizado.
- Comprobadas la conservación de nómina cerrada, sus cálculos y recibos PDF, y las series fiscales independientes sin emitir documentos reales.
- Estas pruebas no representan una instalación en los servidores de un ISP ni envían mensajes o documentos a proveedores externos.
