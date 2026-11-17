# Routly 0.1.45 — Eliminación local de servicios

## Mejora general — todos los países

- En la confirmación de eliminación de un servicio se puede activar **Eliminar solo de Routly, sin modificar MikroTik**.
- Esta opción permite quitar el registro local aunque el router esté desconectado, ya no esté asociado o exista una IP, usuario o MAC compartida con otro servicio.
- La eliminación local no consulta ni envía órdenes a MikroTik. La conexión puede seguir configurada y funcionando allí; el administrador debe revisarla por separado.
- Se libera el puerto NAP y únicamente el equipo vinculado a ese servicio vuelve a Almacén como disponible.
- Se conservan el cliente, sus demás servicios, facturas e historial. Si se elimina el último servicio vigente, el cliente pasa a Retirado.
- La opción comienza desactivada al abrir la confirmación o cambiar de servicio. Sin activarla se conserva la eliminación normal y sus comprobaciones en MikroTik.
- Se mantienen los permisos y el bloqueo de operaciones en curso. El Log distingue la eliminación local.

## Alcance

Esta mejora es general, también para Guatemala y El Salvador. No introduce cambios fiscales ni nuevas emisiones en Digifact. Incluye las mejoras acumuladas de versiones anteriores.

Publicar la versión en Routly Control anuncia su disponibilidad, sin iniciar instalaciones automáticas. Cada administrador del ISP inicia su actualización desde Routly.
