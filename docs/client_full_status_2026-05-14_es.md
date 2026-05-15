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

https://firebasestorage.googleapis.com/v0/b/affinity-dating-app-cf807.firebasestorage.app/o/public-apk%2Fapp-debug.apk?alt=media&token=affinity-apk-7f3c8d92

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

## 3) Apple Sign-In — causa raíz encontrada y código corregido

Después de revisar el código a fondo: el problema **no estaba en la
configuración que hizo la agencia**. La agencia configuró el Service
ID, el Return URL y la clave correctamente — pero la app móvil, en
Android, no estaba pasando esos datos al iniciar el flujo de Apple.
Por eso fallaba aunque todo estuviera bien del lado de Apple.

Ya tengo el código corregido (faltaba el bloque
`webAuthenticationOptions` que conecta la app con el Service ID en
Apple). Solo necesito **un dato puntual de la agencia**: el
identificador del Service ID. Como no tengo contacto directo con
ellos, te dejo abajo el mensaje listo para que sólo lo reenvíes —
sin redactar nada — y en cuanto te lo respondan, yo lo configuro del
lado del código y la siguiente build queda con Apple Sign-In
funcionando en iOS y en Android.

**Mensaje listo para reenviar a la agencia:**

> Hola, una consulta técnica rápida sobre el Sign In with Apple del
> proyecto Affinity (Firebase project `affinity-dating-app-cf807`):
>
> 1. ¿Cuál es el identificador exacto del **Service ID** que crearon
>    en Apple Developer → Identifiers → Services IDs para esta app?
>    (Es la cadena estilo de Bundle ID inverso, p. ej.
>    `com.affinitysocialclub.app.signin` o similar.)
> 2. ¿Podrían confirmar que el **Return URL** registrado en ese
>    Service ID es exactamente
>    `https://affinity-dating-app-cf807.firebaseapp.com/__/auth/handler`?
>    Si tiene otro valor (con/sin barra final, otro subdominio,
>    etc.), pásennoslo tal cual está configurado.
>
> Con esos dos datos terminamos de cerrar el Apple Sign-In de Android
> en la próxima build. Gracias.

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

## Lo único que necesito de tu lado

Probar el APK en un dispositivo Android y avisarme cómo se ve la
nueva separación de Dinámicas. Todo lo demás (registrar SHA-1,
sincronizar `google-services.json`, integrar el Service ID que
respondan los de la agencia) lo hago yo del lado del pipeline en
cuanto tengamos la respuesta — no necesitas tocar la consola de
Firebase ni la de Apple.

Quedo atento.
