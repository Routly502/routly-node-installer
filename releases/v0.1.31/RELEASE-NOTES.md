# Routly 0.1.31 — facturas en cero pagadas

- Toda factura con total final cero queda pagada desde su emisión: manual o automática, de servicio o libre.
- Incluye instalaciones y otros conceptos cuyo descuento cubre el 100 % del importe.
- La factura conserva sus partidas y su documento en cero, sin crear abonos ni ingresos ficticios.
- Al editar una factura y dejarla en cero, su estado también cambia a pagada; si vuelve a tener un importe sin cubrir, vuelve a quedar pendiente.
- Corrige las facturas antiguas de total cero que quedaron pendientes o vencidas, sin alterar las anuladas ni eliminadas.
- El panel deja de contar las facturas de total cero entre las no pagadas o vencidas.
- Cada administrador ISP decide cuándo iniciar la actualización desde Routly.
