# Entrega: Separación de Dinámicas + corrección de errores de inicio de sesión

Hola Alejandra,

Hemos entregado los dos cambios que solicitaste el 12 de mayo, ya en
producción. Pueden revisarlos directamente en el sitio web de
verificación — el APK firmado quedará disponible en una segunda entrega
una vez que termine la limpieza del pipeline.

**Sitio de revisión:** https://affinity-dating-app-cf807.web.app

---

## 1. Separación "Lo que los representa" ↔ "Lo que están buscando"

Las dinámicas, identidad, rol, tipo de interacción, experiencia e
intereses ahora viven en **dos bloques distintos** según el diseño que
nos compartiste:

- **En el perfil** (registro y edición de perfil) verán el bloque
  **"SELECCIONA LO QUE LOS REPRESENTA"** con cinco sub-secciones:
  Identidad individual (Ella/Él), Rol (Ella/Él), Tipo de interacción,
  Experiencia, Intereses. Esto describe a la propia pareja.
- **En el panel de filtros** (botón Filtros del feed) verán el bloque
  **"BUSCANDO"** con las mismas cinco sub-secciones más los toggles
  **Buscando Unicornio** y **Buscando Toro**. Esto describe lo que la
  pareja está buscando en la otra.

El algoritmo del feed ya aplica esta lógica: cada selección en
"BUSCANDO" se compara contra los campos correspondientes del perfil
de la otra pareja, por lo que los filtros expresan una preferencia
sobre el otro lado y no sobre un conjunto compartido.

## 2. Mensajes de error específicos en el registro e inicio de sesión

El error genérico **"Error al registrarse"** que reportaste ya fue
reemplazado por mensajes específicos según la causa real:

- **Registro:** correo ya registrado, contraseña débil, correo
  inválido, demasiados intentos, sin red.
- **Inicio de sesión por correo:** usuario no encontrado, contraseña
  incorrecta, credencial inválida, correo inválido, cuenta deshabilitada,
  demasiados intentos.
- **Google Sign-In:** detecta error de configuración SHA-1 y muestra
  el mensaje correcto en lugar de fallar en silencio.

Cada mensaje está localizado en español y en inglés.

---

## Próximos pasos por su lado

1. Revisar en el sitio web los dos bloques nuevos (perfil + filtros) y
   confirmarnos si la jerarquía visual coincide con su mockup.
2. (Opcional) Validar los textos en español de las cinco sub-secciones
   por si quieren afinarlos antes de la build final del APK.

## Próximos pasos por nuestro lado

1. Liberar la cuota de artefactos en el pipeline para volver a publicar
   el APK descargable.
2. Aplicar cualquier ajuste de texto que nos indiquen tras la revisión.

Quedamos atentos a su confirmación.
