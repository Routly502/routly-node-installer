# Routly 0.1.52 — Configuración de correo y proveedor exclusivo

## Correcciones de correo

- Se elimina «URL pública de esta instalación» del formulario de correo. Configurar Brevo, Resend o SMTP ya no exige un dominio público ni HTTPS de entrada.
- Guardar el proveedor no elimina un valor interno de recuperación previamente configurado. Sin ese valor no se generan enlaces de recuperación; se conserva la validación de enlaces seguros.
- Los proveedores no configurados muestran remitente, correo y credencial vacíos; ya no copian los datos de otra opción. Los borradores de la pantalla permanecen separados.
- Solo un proveedor puede estar habilitado. Mientras uno esté activo, los otros quedan bloqueados; para cambiar, hay que desactivar y guardar el actual primero.
- El proveedor nuevo exige su propia clave o contraseña. No se reutiliza automáticamente una credencial guardada para otro proveedor.
- La exclusividad también se comprueba en el servidor y ante solicitudes simultáneas.
- Verificar conexión no puede probar otro proveedor usando la configuración guardada del anterior.
- Guardar otro proveedor reemplaza la configuración anterior; la pantalla informa de este comportamiento. Cambiar de opción sin guardar no modifica la configuración del servidor.
- Las credenciales permanecen cifradas y las plantillas existentes no se sobrescriben al guardar el servicio.

## Actualización

- Versión acumulativa posterior a 0.1.51; conserva sus correcciones de saldo a favor por HTTP y mejoras de facturación electrónica.
- No activa el correo ni realiza envíos como parte de la actualización.
- No instala certificados, expone el servidor, cambia reglas de MikroTik ni traslada datos, credenciales o identidad entre ISP.
- Publicar la disponibilidad en Control no instala automáticamente: el administrador del ISP inicia la actualización desde su panel.

## Validación y límites

- Pruebas con credenciales sintéticas, persistencia, bloqueo entre proveedores y solicitudes simultáneas.
- Paquete compilado validado en Node.js 22, instalación nueva y actualización desde 0.1.51 en un entorno aislado.
- No se han enviado correos reales mediante la cuenta del ISP ni se considera comprobada su entrega en Brevo.
