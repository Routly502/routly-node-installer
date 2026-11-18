# Routly 0.1.47 — OLTs y estado de clientes

## Cambios generales — todos los ISP y países

- Se incorpora Gestión de OLTs con conexión directa desde el servidor de Routly, sin depender de SmartOLT.
- Inventario para Huawei, ZTE, FiberHome y VSOL: agregar, consultar, editar y eliminar registros, buscar, filtrar, ordenar y exportar.
- Configuración de SSH o Telnet, puertos TCP y UDP de referencia, credenciales cifradas, fabricante, modelo y tipo de PON.
- Pruebas manuales de autenticación y lectura de versión/modelo, sin modificar la configuración de las OLTs. Se advierten diferencias de modelo o cambios de versión.
- Se corrige la sincronización del estado del cliente con sus servicios: un cliente sin servicios activos y con servicios suspendidos se muestra como suspendido y aparece en el filtro correspondiente. Si conserva algún servicio activo, permanece activo. La actualización reconcilia las etiquetas existentes sin enviar órdenes al MikroTik ni alterar facturas.
- En Finanzas → Facturación, pulsar el nombre del cliente abre directamente su perfil en la pestaña Facturación.
- Paquete acumulativo: conserva las correcciones generales incluidas en versiones anteriores.

## Alcance de OLTs

- El estado de conexión refleja la última prueba manual, no monitoreo continuo.
- Traps SNMP y VPN se muestran como «Sin verificar». Esta versión no recibe traps ni crea o verifica túneles VPN. El puerto UDP se guarda como referencia.
- Registrar un modelo no garantiza compatibilidad con todos sus firmwares. La conexión se verificó con equipos simulados; falta validar modelos reales.
- Eliminar una OLT solo borra su registro en Routly; no envía comandos al equipo.
- Telnet transmite credenciales en texto plano; se recomienda SSH o una red de gestión aislada.

## El Salvador

- No se añaden cambios exclusivos de país en esta versión.
- El seguimiento de certificaciones rechazadas o sin confirmar continúa pendiente con Digifact. No se anuncia su resolución, no se reenvían documentos automáticamente y no se deben repetir cobros para intentar obtener otro documento fiscal.

## Actualización

Preparar el paquete no publica disponibilidad en Routly Control ni instala actualizaciones. Una vez publicada la versión, cada administrador del ISP decide cuándo actualizar desde Configuración → Actualizaciones.
