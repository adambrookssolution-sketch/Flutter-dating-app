# Apple Sign-In activado — confirmación a Alejandra

Hola Alejandra,

Listo, ya activé Apple Sign-In con el Service ID que nos pasaron de
la agencia (`com.affinitysocialclub.web`). La nueva build ya está
publicada en el mismo enlace estable de siempre — al volver a
descargar desde ahí la app trae los dos métodos funcionando:

**APK (mismo enlace, refrescado automáticamente):**

https://firebasestorage.googleapis.com/v0/b/affinity-dating-app-cf807.firebasestorage.app/o/public-apk%2Fapp-debug.apk?alt=media&token=affinity-apk-7f3c8d92

**Lo que cierra en esta build:**

- ✅ **Apple Sign-In en Android e iOS** — la app ahora pasa el Service
  ID y el Return URL al iniciar el flujo de Apple, que era la pieza
  que faltaba.
- ✅ **Google Sign-In en Android** — la huella SHA-1 del keystore
  quedó registrada automáticamente en Firebase y el
  `google-services.json` se sincroniza desde la consola en cada
  build.

**Lo que sigue:**

Por favor, avisa a la agencia que Apple Sign-In ya quedó activado del
lado del código y pueden probar con cualquier Apple ID de prueba. Si
detectan algo raro en el flujo, me lo pasan y lo ajusto en la
siguiente build.

Las tres observaciones nuevas que mandaste (búsqueda en mensajes,
feed por idioma, selector de idioma en la app) entran en el siguiente
sprint y las entregamos en el próximo APK estable, en el mismo
enlace de siempre.

Quedo atento.
