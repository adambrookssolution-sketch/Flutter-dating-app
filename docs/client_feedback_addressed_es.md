# Respuesta a la auditoría del 30-abr-2026

> Para enviar por WhatsApp después del mensaje de migración a producción.
> Clienta listó 10 puntos tras probar el APK. Este mensaje los responde
> uno por uno, sin agendar nada para "después" salvo el #9 que ella misma
> dijo enviarme hoy con la especificación. Tono: socio que va resolviendo
> y reportando, no proveedor que excusa.

---

Alejandra, leí tu lista del 30 con calma y te paso el cierre punto por punto.
Está todo en código y subido ya — sale en el próximo build de GitHub Actions.

1) Buscador en mensajes
   Listo. La pantalla de Mensajes ahora abre con una barra de búsqueda
   que filtra Solicitudes y Chats en tiempo real por nombre de la pareja
   y por último mensaje. Cuando una cuenta tenga miles de conversaciones
   va a seguir respondiendo igual.

2) Resultados según idioma del usuario
   Listo a nivel de datos: cada pareja ahora guarda el idioma con el que
   se registró (es / en) y el feed lo usa como criterio para priorizar
   parejas que hablen el mismo idioma. No bloquea las otras —
   simplemente las muestra después.

3) Selector de idioma en la app
   Listo. Lo puse en Configuración → Idioma, con tres opciones:
   "Predeterminado del sistema", "Español", "English". El cambio se
   aplica en caliente y se guarda — la próxima vez que abra la app ya
   recuerda la elección.

4) Filtro por país en el feed
   Listo. Dentro del filtro de la piña agregué un selector de país
   (México, Colombia, Argentina, Chile, Perú, Venezuela, Uruguay,
   Ecuador, España, USA por ahora). Filtra contra el país de
   registro de la pareja. Sumar más países es una línea de código —
   me dices cuáles quieres y los meto.

5) Etiqueta de contenido explícito
   Listo, exactamente como propusiste:
     · La pareja tiene un switch en el perfil para marcar su contenido
       como explícito.
     · Por defecto ese contenido NO aparece en el feed normal.
     · Dentro del filtro de la piña hay un switch "Mostrar contenido
       explícito"; al activarlo, el feed muestra ÚNICAMENTE las parejas
       marcadas como explícitas — funciona como un feed separado.
   Es la implementación más limpia: una sola colección, un campo
   booleano, dos modos de consulta. No hay dos feeds que sincronizar.

6) Panel de administración (reportes / bloqueos / moderación)
   Listo. El panel ahora es de tres pestañas: VERIFICACIONES,
   REPORTES, BLOQUEOS. Verificaciones es lo que ya conocías.
   Reportes lista todas las denuncias entrantes (más recientes
   primero) con su categoría y motivo, para que veas el flujo
   completo aunque la regla de auto-suspensión a 5 reportes en 30
   días siga ejecutándose sola en el servidor. Bloqueos muestra
   quién bloqueó a quién, distinguiendo bloqueos manuales de los
   automáticos por suspensión.

7) Lista de motivos al reportar
   Resuelto. Antes el botón Reportar abría un atajo que solo decía
   "gracias por tu reporte" — ese atajo era un placeholder. Ahora
   abre el formulario real con las 6 categorías: Perfil falso,
   Acoso, Contenido no consensuado, Sospecha de menor de edad,
   Spam, Otro. La pareja describe libremente y el motivo entra al
   panel de administración del punto 6.

8) "No new couples to recover right now"
   Ese texto no está en nuestro código — es un literal heredado del
   build anterior de la agencia. En el momento que la migración a
   producción active nuestra versión, ese mensaje desaparece.

9) Cambios de lógica en intereses y filtros
   Quedo a la espera de la especificación que me dijiste pasar hoy.
   En cuanto la tenga, la integro sobre lo que ya está armado.

10) Pantallazo de error al abrir la app
    Diagnosticado. Lo que veías eran dos splash sucesivos con un
    flash blanco entremedio: el primero es el splash que Android
    arma con tu ícono adaptable, y el segundo es nuestro splash
    burgundy con el wordmark Affinity. El "error" era ese parpadeo
    blanco entre los dos. Ya lo arreglé: ahora el fondo de la
    ventana nativa también es burgundy, así que en vez de
    parpadear en blanco, los dos splashes se ven encadenados sin
    corte. En el siguiente APK lo notarás de inmediato.

Resumen ejecutivo:
   8 de 10 puntos quedaron resueltos en código ya. El #8 desaparece
   solo con la migración. El #9 espera tu spec.

Avísame cuando termines la lista de cambios del #9 y la dejo dentro
del mismo build, así te llega un solo APK con todo en una pasada.

Saludos,
Gabriel
