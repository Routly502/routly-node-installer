Routly 0.1.28 — respaldos completos y portables

- Nuevo panel de Respaldos del sistema en Configuración > Sistema: generar manualmente, subir, descargar y restaurar respaldos.
- Formato .routly-backup con datos, configuraciones, usuarios, contraseñas portables, logos y archivos adjuntos del ISP. No incluye la licencia ni la identidad de la instalación.
- Permite restaurar en otro servidor donde Routly ya esté activo, conservando la licencia y la identidad del destino.
- Respaldos programados habilitados con el horario guardado del ISP y el mismo formato completo del respaldo manual.
- Eliminadas las comprobaciones periódicas y alertas por ausencia o antigüedad del backup. Un fallo programado registra un solo error, sin reintentos repetitivos durante el día; una ejecución manual registra un único resultado.
- Los respaldos exitosos actualizan el último respaldo disponible. El éxito programado no genera un aviso rutinario adicional.
- Confirmación de restauración, copia previa y recuperación de operaciones interrumpidas.
- Actualización acumulativa, sin nuevas migraciones de esquema respecto de 0.1.27. Cada ISP inicia voluntariamente la actualización desde su panel.
