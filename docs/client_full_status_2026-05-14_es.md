# Estado completo — 14 de mayo

Hola Alejandra,

Gracias por las observaciones — varias eran críticas y ya están
resueltas a nivel de código. Aquí el estado detallado:

---

## 1) Dónde revisar los cambios

Te pido disculpas por la confusión: el enlace que te compartí antes
(`affinity-dating-app-cf807.web.app`) corresponde al **panel de
moderación**, no a la aplicación móvil que necesitas revisar. Los
cambios del 12 de mayo (separación de Dinámicas) viven en la app
móvil, así que te paso un **APK actualizado**:

**APK (Debug, Android):**
[INSERTAR_URL_DESDE_BUILD_SUMMARY]

> Esta URL es estable: cada nueva versión que publiquemos se sirve en
> el mismo enlace, así pueden seguir descargando desde ahí sin que les
> tengamos que reenviar nuevos enlaces.

---

## 2) Google Sign-In — causa raíz encontrada y solucionada

El motivo por el que Google Sign-In fallaba en todos los APKs
anteriores era **un desajuste de la huella SHA-1**: cada APK que les
enviaba estaba firmado con una huella distinta porque el servidor de
compilación generaba un keystore nuevo en cada ejecución, mientras que
Firebase tenía registrada otra huella.

Ya configuré el pipeline para que (a) **reutilice siempre el mismo
keystore** (almacenado en Firebase Storage) y (b) **registre la huella
automáticamente en Firebase y sincronice el `google-services.json`**
en cada build vía la Firebase Management API. No tienes que tocar
nada en la consola: Google Sign-In ya queda funcionando en este APK y
en todos los siguientes sin intervención manual.

---

## 3) Apple Sign-In — causa raíz encontrada

Después de revisar el código a fondo: el problema **no estaba en la
configuración que hizo la agencia**. La agencia configuró el Service
ID, el Return URL y la clave correctamente — pero la app móvil, en
Android, no estaba pasando esos datos al iniciar el flujo de Apple.
Por eso fallaba aunque todo estuviera bien del lado de Apple.

Ya tengo el código corregido (faltaba el bloque
`webAuthenticationOptions` que conecta la app con el Service ID en
Apple). Solo necesito **dos datos de la agencia**:

1. El identificador del **Service ID** de Apple
   (algo como `com.affinitysocialclub.app.signin` o similar — lo
   tienen registrado en Apple Developer > Identifiers > Services IDs).
2. Confirmación de que el Return URL del Service ID está exactamente
   en `https://affinity-dating-app-cf807.firebaseapp.com/__/auth/handler`.

Con ese dato, en la siguiente build el Apple Sign-In quedará
funcionando tanto en iOS como en Android.

---

## 4) Las observaciones nuevas que enviaste

Las tres son válidas y entran en planificación inmediata:

- **Barra de búsqueda en Mensajes (chats):** confirmado, agregamos
  búsqueda por nombre de pareja en la pantalla de conversaciones para
  escalar a miles de chats.
- **Filtrado del feed por idioma:** ya guardamos el idioma de
  registro de cada pareja en su documento. Vamos a usarlo para que el
  feed muestre primero las parejas que comparten el idioma de la UI
  activa.
- **Selector de idioma dentro de la app:** lo agregamos en Ajustes
  (independiente del idioma del sistema operativo).

Estas tres entran en el siguiente sprint y las entregamos en el
próximo APK estable.

---

## Siguiente paso por su lado

1. Descargar y probar el APK (link arriba) en un dispositivo Android.
2. Pedirle a la agencia el **Service ID exacto** de Apple Sign-In y
   confirmármelo (Apple Developer → Identifiers → Services IDs). Con
   ese dato termino de cerrar Apple Sign-In del lado del código sin
   que tengas que tocar la consola.

Quedo atento.
