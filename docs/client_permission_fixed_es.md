# Mensaje — permisos arreglados, retesting pedido (03-may-2026)

> Para WhatsApp. Va después de que Alejandra mandó las 5 capturas con
> errores `permission-denied` y los textos sueltos en el perfil.
> Tono: diagnóstico claro + acción tomada + invitación a retestear.

---

Alejandra, vi tus 5 capturas y te las contesto en una.

Las 4 que decían "permission-denied" venían todas del mismo origen:
las reglas de seguridad de Firestore y Storage estaban escritas y
verificadas en mi lado, pero todavía no se habían publicado en el
proyecto de producción. Mientras eso no estaba arriba, Firebase
rechaza por defecto cualquier lectura/escritura — eso es lo que
veías en Manage Trips, Security, Submit verification, y la pantalla
de grabar video.

Acabo de desplegarlas en este momento contra
`affinity-dating-app-cf807` desde mi máquina, sin pasar por el
GitHub Actions todavía (ese paso llegará cuando tengamos el secret
del key configurado en el repo, pero el resultado en producción ya
es el mismo: las reglas están vivas).

Lo que quedó publicado:
  • firestore.rules  (lectura/escritura por dueño + claim de moderador)
  • firestore.indexes.json (búsquedas por status, geohash, sent_at)
  • storage.rules  (subida de fotos + video de verificación a la pareja
    autenticada)

Sobre la pantalla del perfil con "()" debajo del switch de "Mark this
post as explicit" y el botón "..." mientras guarda: dos detalles
cosméticos. El "()" pasaba porque el subtítulo era vacío y el
componente lo envolvía igual; ya está corregido para que ese paréntesis
desaparezca cuando no hay subtítulo. El "..." era el placeholder de
"guardando" — lo cambié al texto de "Enviando..." que ya usábamos en
otras pantallas para que se sienta natural.

Lo que te pediría ahora:

  1. Espera ~10 minutos a que termine el siguiente build de GitHub
     Actions (sale automáticamente con los dos arreglos cosméticos
     adentro).
  2. Instalá ese APK encima del que tenías.
  3. Volvé a probar el flujo completo:
       · registro → subir fotos → grabar video → submit
       · entrar al panel https://affinity-dating-app-cf807.web.app
         con tu correo licmkt.alejandraavelar@gmail.com
       · aprobar/rechazar la pareja desde el panel

Las funciones del servidor (la que decide aprobar/rechazar moderación)
todavía no están desplegadas — eso queda atado al paso pendiente de
habilitar las 7 APIs de Google Cloud en consola y subir la key como
secret de GitHub. Pero el flujo hasta el punto de "enviar para
revisión" ya tiene que funcionar de extremo a extremo en este APK
nuevo.

Si algo sigue dando error, mandame la captura tal como hiciste hoy —
con el texto exacto del mensaje me alcanza para diagnosticarlo en
minutos.

Saludos,
Gabriel
