# Respuesta a la especificación del flujo de registro

---

**Versión WhatsApp (recomendada):**

---

Perfecto María, todo muy claro. Lo tomo así tal cual:

**Registro como pareja (un solo perfil):**
- Nombres, fechas de nacimiento, ciudad/país, descripción → obligatorios
- Altura → opcional
- Mínimo **3 fotos obligatorias de la pareja juntos** — si no hay 3, el botón de "Siguiente" queda bloqueado. Después del registro ya pueden editar/agregar/quitar libremente.

**Video de verificación:**
- Botón "Verification Video" dentro del flujo
- Pantalla dedicada explicando el objetivo (comunidad segura y real)
- Video de 3–5 segundos: ideal con ambos, permitido uno solo
- Instrucción: mirar al frente, girar cabeza a la derecha, luego a la izquierda
- Botón para guardar y finalizar el registro

**Estado "pendiente de verificación":**
- Una vez enviado, la pareja **no accede a nada** de la app (ni feed, ni mensajes, ni perfiles)
- Solo ve una pantalla indicando que está en revisión

**Panel web de moderación (admin):**
- Ve fotos, video, nombres, edad calculada desde fecha de nacimiento, ubicación, descripción
- Dos acciones: **Aprobar** (estado → `activo`, acceso completo inmediato) o **Rechazar** con motivo obligatorio (fotos no coinciden / video poco claro / perfil sospechoso / etc.)

**Reintentos tras rechazo:**
- 2 intentos adicionales después del primer rechazo
- Al tercer rechazo → cuenta bloqueada definitivamente

**Estados del sistema:**
- `pendiente de verificación` → sin acceso
- `rechazado` → con opción de reintento si aplica
- `activo` → acceso completo

Con esto ya tengo todo el flujo perfectamente delimitado. Arranco con la implementación esta misma semana en paralelo con los otros componentes, y le mando capturas del panel web en cuanto tenga la primera pantalla funcionando.

Solo un par de preguntas pequeñas cuando tenga un momento:

1. Para el video de verificación, ¿prefiere que quede guardado para siempre en el panel (por si el perfil se reporta después) o que se elimine automáticamente a los 7 días dejando solo un hash como referencia? (Esto lo habíamos hablado en la spec técnica pero quería confirmar con usted antes de implementarlo).

2. Para los motivos de rechazo, ¿quiere una lista cerrada (el admin elige de un menú) o un campo libre donde escribe el motivo? Yo recomendaría la lista cerrada más un campo libre opcional, para mantener consistencia en las notificaciones.

Ningún bloqueante, avanzo con la implementación y estas preguntas las podemos resolver cuando usted pueda.

Saludos,
Gabriel
