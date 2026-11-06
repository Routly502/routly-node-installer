- Corrige la generación de respaldos con historiales grandes de tráfico y monitoreo mediante procesamiento incremental, sin eliminar esos historiales.
- Mantiene la lectura de respaldos antiguos y valida la integridad de los archivos antes de restaurarlos. Los respaldos nuevos requieren un Routly actualizado y no pueden abrirse con versiones anteriores.
- Conserva el máximo de 512 MiB por archivo comprimido; el nuevo formato admite hasta 8 GiB descomprimidos y aplica límites explícitos por registro y archivo adjunto.
- Mejora el diagnóstico de respaldos con una etapa y un código de error seguros, sin registrar contraseñas ni consultas completas.
- Corrige el bloqueo de Monitoreo al cargar historiales extensos.
- Amplía Monitoreo con comprobaciones ICMP y SNMP independientes, sensores, intervalos configurables y sondeo persistente.

Publicar esta versión en Routly Control solo la pone a disposición. Cada administrador del ISP decide cuándo iniciar la actualización desde Routly.

La instalación y el funcionamiento con datos y equipos reales del ISP deben confirmarse después de actualizar el Node. Las validaciones del paquete no sustituyen esa comprobación.
