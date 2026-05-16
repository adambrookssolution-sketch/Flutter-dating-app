# Migración a producción — estado y dos pedidos puntuales (30-abr-2026)

> Mensaje plano para WhatsApp. Va después de que ella mandó la
> service-account key del Firebase real (affinity-dating-app-cf807).
> Tono: progreso concreto + dos pedidos accionables específicos
> que solo ella puede destrabar (no se los puedo destrabar yo
> con la key que ya tengo).

---

Alejandra, ya empecé la migración al ambiente real con la key
que me pasaste. Avancé hasta donde la propia llave me deja;
hay dos cosas que solo tú (o tu equipo de la agencia) pueden
resolver desde su lado, te las explico al final.

LO QUE YA QUEDÓ HECHO sobre affinity-dating-app-cf807:

  • Toda la app (Android, iOS, Web) ya está apuntando a este
    proyecto, no al de pruebas. Cuando salga el próximo APK
    se va a conectar contra tu Firebase real.
  • Creé la app Web "admin-web" dentro del proyecto, para que
    el panel de moderación se sirva desde tu propio dominio
    (https://affinity-dating-app-cf807.web.app) en cuanto
    desplegamos.
  • Activé tu correo principal (licmkt.alejandraavelar@gmail.com)
    como moderador en el ambiente real — vas a poder entrar
    al panel directo con ese correo, sin pasos extra.
  • Dejé sembrada una pareja de prueba en estado "pending_review"
    para que cuando entres al panel ya tengas una pareja en cola
    para aprobar/rechazar y verificar el flujo completo.
  • Las funciones del servidor (las que procesan las decisiones
    de moderación, denuncias, suspensiones, eliminación con 30
    días, etc.) están compiladas, listas para desplegar.

LOS DOS PEDIDOS — sin esto no puedo cerrar la migración:

1) Habilitar 7 APIs de Google Cloud
   La key que me pasaste sirve para leer/escribir datos pero
   no tiene permiso para "encender" los servicios necesarios
   en Google Cloud. Necesito que alguien con rol de Owner
   en el proyecto (tú o la agencia) entre a:

       https://console.cloud.google.com/apis/library?project=affinity-dating-app-cf807

   y active estas siete APIs (botón azul "Enable" en cada una):
       - Cloud Functions API
       - Cloud Build API
       - Artifact Registry API
       - Eventarc API
       - Cloud Run Admin API
       - Pub/Sub API
       - Cloud Scheduler API

   Es un par de clicks por API, no cobran nada por activarlas
   (solo se cobra por uso real, y el plan gratuito de Blaze
   es generoso para una app de este tamaño).

2) Cargar la key como secret en GitHub
   Para que el deploy quede automatizado y reproducible, la
   key tiene que vivir en GitHub Secrets (no la voy a versionar
   en el código, va cifrada). Necesito que alguien con acceso
   admin al repo:

       https://github.com/adambrookssolution-sketch/Flutter-dating-app/settings/secrets/actions

   cree un secret llamado FIREBASE_SA_KEY_PROD y pegue ahí
   el contenido completo del JSON que me mandaste.

   Si tú no tienes ese acceso al repo, dime quién lo tiene y
   coordinamos directo, o si prefieres me das tú los datos de
   acceso temporal y yo lo configuro.

CUANDO ESOS DOS PUNTOS ESTÉN:
  Yo lanzo el deploy desde GitHub Actions (15 minutos) y queda
  todo vivo en producción. A partir de ahí tú entras al panel
  con tu correo, ves la pareja de prueba que dejé sembrada,
  pruebas Aprobar y Rechazar, y verificas el flujo completo
  end-to-end. Ese es exactamente el milestone que mencionaste
  para el 50% restante.

Si me destrabaste hoy los dos puntos, mañana mismo ya estás
probando moderación real. Si quieres puedo armar una llamada
corta con tu equipo de agencia para guiarlos al activar las
APIs — son 5 minutos.

Saludos,
Gabriel
