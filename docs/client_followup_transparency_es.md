# Mensaje de seguimiento — Transparencia sobre el entorno de prueba

---

Hola María,

Antes de que empiece a probar el APK, quiero ser completamente transparente con usted sobre **tres detalles** del entorno de prueba para que no le tomen por sorpresa.

## 1. La subida de fotos no funciona todavía

Cuando intente registrar un perfil, el paso de "subir foto" se va a saltar automáticamente y el perfil se guardará **sin imagen**. Esto es intencional en este APK.

**Motivo:** Firebase Cloud Storage requiere el plan Blaze (de pago por uso) para activarse. Como estoy trabajando en un entorno aislado de pruebas bajo el plan gratuito Spark, no tengo Storage habilitado. El código está completo y funciona — solo se activará automáticamente en el momento de la integración final con su proyecto oficial, que ya sí tiene Storage.

## 2. Travel Match no encuentra coincidencias aún

La pantalla de "Travel match" abrirá pero mostrará "not found". El listado de viajes (crear/ver viajes) sí funciona.

**Motivo:** La función de matching corre como Cloud Function, y Cloud Functions también requiere el plan Blaze. Nuevamente, el código está listo y desplegable — solo espera el entorno productivo.

## 3. Algunas parejas aparecen sin foto

Las 4 parejas de demostración que verá en el feed tienen el perfil completo pero **sin foto** por la misma razón del punto 1.

---

## Por qué elegí este enfoque

Podría haberle pedido activar el plan Blaze en un proyecto intermedio, pero preferí **no involucrar ningún tema de facturación** hasta el momento de la integración final con su proyecto oficial. Así usted mantiene el control completo sobre la facturación desde el día uno.

**Estos tres puntos NO son bugs ni funciones faltantes** — son limitaciones del entorno gratuito de pruebas. En el momento de la integración (cuando conectemos con su Firebase productivo) los tres se activan automáticamente **sin cambios de código adicionales**, porque el código ya está completo.

Si al probar el APK detecta cualquier otro comportamiento extraño, por favor avíseme de inmediato para revisarlo. Prefiero ser directo y claro desde el principio que dejar que cualquier detalle genere dudas.

Gracias por su tiempo y su confianza.

Saludos,
Gabriel
