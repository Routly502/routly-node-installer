# Routly 0.1.42 — Datos fiscales y correcciones de acceso local

- Permite guardar la ficha fiscal de El Salvador al registrar o editar un cliente y precargar su preferencia, receptor e IVA al registrar un pago total.
- Incluye las actividades económicas, departamentos, municipios y distritos del Excel proporcionado, con búsqueda de actividad por código o descripción y selección geográfica dependiente.
- Incorpora tipo de persona y adapta las etiquetas del documento de identificación. El nombre y la identificación se ingresan manualmente, sin consultas externas.
- Para CCF solo permite NIT. En Solo recibo oculta los campos fiscales sin borrar la ficha guardada.
- Ordena los campos de Factura y CCF: documento, nombre o razón social, actividad, tipo de persona, departamento, municipio, distrito, dirección completa, correo y teléfono.
- Corrige el identificador de los cobros para el acceso por HTTP a una IP privada, conservando su generación criptográfica y protección de reintentos.
- Corrige la apertura de Factura libre y la adición y edición de partidas manuales o del catálogo por HTTP local, sin depender de crypto.randomUUID.

La facturación habitual de Routly no certifica documentos fiscales. La emisión opcional de Factura o CCF de este flujo sigue limitada al pago total. No se reescriben facturas emitidas ni se vincula el catálogo de factura libre con movimientos de almacén.

IMPORTANTE: esta actualización no activa producción fiscal ni modifica las credenciales o la identidad del ISP. La producción de Digifact sigue sujeta a la confirmación y configuración correspondientes.

Se conservan datos y archivos locales. Registrar o publicar esta versión en Routly Control no inicia instalaciones automáticamente: cada administrador del ISP decide cuándo actualizar desde su panel.
