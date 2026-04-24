# Mensaje de entrega de APK — fase de validación

---

Hola María,

Te paso el APK para que puedas probar Affinity en tu teléfono Android.
Antes de que lo abras, quiero explicarte exactamente qué vas a estar
probando y cómo sacarle el máximo provecho en esta fase.

## Qué es esto

Es la **build de validación interna** — no es la versión de producción.
Corre contra un entorno de pruebas aislado (una copia de Firebase
separada de tu proyecto oficial) para que podamos validar sin tocar
ningún dato real.

## Cómo instalar

1. Descarga `app-release.apk` que te paso junto a este mensaje.
2. En tu teléfono, activa "instalar desde fuentes desconocidas"
   (Ajustes → Seguridad) cuando te lo pida.
3. Toca el archivo → Instalar → Abrir.

## Dos caminos para que pruebes todo

Te propongo que la validación la hagas por **dos caminos complementarios**
— cada uno cubre cosas distintas.

### Camino A — Registrarte con tu propio email (recomendado primero)

Esto es para que veas el flujo completo de **un usuario nuevo**:

1. Abre la app → "Crear cuenta" → usa tu email personal y la contraseña
   que quieras.
2. Completa el perfil de pareja (nombres, fechas, ciudad, descripción,
   intereses).
3. Sube 6 fotos — **cualquier imagen sirve** (un paisaje, una captura,
   lo que tengas a mano). Es solo prueba.
4. Graba el video de verificación (3–5 s, miras al frente, giras a la
   derecha, giras a la izquierda).
5. Vas a llegar a una pantalla de **"Pendiente de revisión"**.

**En ese momento me escribes por WhatsApp** diciendo "ya envié el
video" y **en menos de 1 minuto yo te apruebo desde mi lado**. La
pantalla de la app va a pasar sola al feed — sin reinstalar ni nada.

Con esto ves: registro completo, pantalla de espera, y el momento
exacto en que una pareja recibe la aprobación.

### Camino B — Entrar con mi cuenta de prueba (para ver todo lo demás)

Para que no tengas que esperar nada y puedas probar el resto de la
app directo, te dejo mis credenciales:

- **Email:** `jenith.solution@gmail.com`
- **Contraseña:** (te la paso por WhatsApp aparte, para no dejarla
  escrita aquí)

Esta cuenta ya está aprobada y ya tiene algo de actividad de pruebas
previas. Con ella vas a poder probar sin demora:

- El feed de parejas con scroll vertical (una pareja a la vez)
- Filtros: edad, dinámicas, experiencia, intereses, ubicación,
  Travel Match
- Abrir una pareja → "Start Conversation" → mandar solicitud
- Inbox: ver solicitudes recibidas, aceptar/rechazar, abrir chat
- Manage Trips → agregar un viaje → ver Travel Match
- Perfil → Security → lista de bloqueos
- Cambio de idioma (ES/EN)

Una nota sobre esta cuenta: **es mi cuenta real de desarrollador**,
así que en el Inbox vas a ver conversaciones y solicitudes de pruebas
anteriores. Es normal — es la evidencia de que el sistema ha estado
funcionando. Puedes ignorarlas o abrirlas para ver cómo se ve un chat
real.

## Qué funciona al 100% en esta build

- ✅ Registro y login con email
- ✅ Perfil completo con intereses, dinámicas, experiencias
- ✅ Feed de parejas con filtros y scroll por cards
- ✅ Botón piña dorada arriba + Start Conversation fijo abajo
- ✅ Solicitudes: enviar, recibir, aceptar, rechazar
- ✅ Chat entre parejas conectadas
- ✅ Bloqueo y reporte desde el menú de la tarjeta
- ✅ Travel Match (destinos + fechas + matching)
- ✅ Cambio de idioma ES/EN
- ✅ Verificación por video end-to-end (con mi aprobación manual)

## Lo que sabemos que todavía no se activa en esta build

Te lo cuento con transparencia para que no te tome por sorpresa —
**ya está resuelto en el código**, pero requiere configuración externa
que solo tiene sentido encender al pasar a tu Firebase oficial:

1. **Recuperación de contraseña por correo.** El botón funciona, pero
   el correo no llega porque todavía no está conectado el servidor de
   correo profesional (SendGrid). Si se te olvida la contraseña que
   usaste en el Camino A, me escribes y te la reseteo en 30 segundos.
   En producción queda resuelto el problema del spam que mencionaste.

2. **Autocompletado de Google Places.** En este entorno usa un fallback
   simple (escribes la ciudad a mano). En producción es el autocomplete
   de Google con sugerencias en tiempo real, con las claves que ya
   tengo preparadas.

3. **Notificaciones push.** Los tokens se registran correctamente; el
   envío desde el servidor depende de Cloud Functions (plan pagado).
   En tu Firebase oficial se activa día 1.

4. **Subida de fotos a Cloud Storage.** Si intentas subir fotos puede
   que queden guardadas solo localmente. Storage requiere plan pagado
   de Firebase y lo activamos al migrar a tu proyecto. El perfil igual
   se guarda con los demás campos.

5. **Panel web de moderación.** El código está listo pero todavía no
   lo he desplegado en una URL — por eso estoy yo aprobando desde la
   terminal en esta fase. En producción será una URL propia
   (`affinity-admin.web.app` o similar) donde tú y los moderadores
   entran con su usuario.

**Ninguno de estos cinco puntos es código faltante** — son
activaciones que solo cuesta conectar una vez que estemos en tu
Firebase real.

## Qué me gustaría que valides

1. **La experiencia visual coincide con los mockups** que me mandaste
   (piña, card, pantalla de filtros, perfil).
2. **El flujo registration → profile → video → feed** se siente fluido.
3. **Los filtros filtran de verdad** — aplica "Soft Swap" o un interés
   y debería reducirse la lista visible.
4. **El scroll vertical del feed** (una pareja a la vez) se siente
   natural.
5. **Cualquier cosa que te chirríe** — un texto en inglés, un botón
   que no responde, una pantalla que se ve rara, un color que no
   cuadra. Mándame captura y lo anoto.

No te preocupes por lo que listé en "lo que no se activa" — eso ya
está resuelto, simplemente no se ve en este entorno de pruebas.

## Lo que viene después de tu validación

Cuando me des luz verde sobre lo visual y el flujo:

1. Migramos a tu Firebase oficial (1 día): claves de Google Places,
   servidor de correo, activación de Storage y Cloud Functions.
2. Segunda ronda corta de validación ya en el entorno real.
3. Despliegue del panel web de moderación para ti y tu equipo.
4. Preparación de assets y subida a Google Play + App Store (requiere
   tus cuentas de desarrollador — si quieres te explico ese paso
   aparte).

## Cosas prácticas mientras pruebas

- **Si te quedas atascada en la pantalla de "Pendiente de revisión"**
  del Camino A: mándame WhatsApp. En 1 minuto te apruebo y la app
  pasa sola al feed (puedes tirar hacia abajo para refrescar si no
  cambia al toque).
- **Si se te olvida la contraseña del Camino A**: te la reseteo yo,
  me avisas.
- **Cualquier bug o detalle**, por pequeño que sea: captura +
  WhatsApp. Te digo al momento si es algo a corregir o algo esperado
  de este entorno.

## Una aclaración sobre los dos proyectos

Todo lo anterior es **Affinity** (la app móvil). El tema del bot de
Telegram para monetizar tus grupos es un proyecto totalmente aparte
que estamos evaluando en paralelo — las dos cosas no se mezclan y no
afectan entre sí.

Quedo atento a tus comentarios. Tómate el tiempo que necesites, yo
estoy disponible para aprobarte la verificación en cuanto envíes el
video.

Saludos,
Gabriel
