# Propuesta — Módulo de Suscripciones para Affinity (Free / Gold / Black)

> Documento formal para enviar a la cliente (WhatsApp o correo).
> Extensión intencional: ~1.400 palabras. La cliente pidió
> "bastante acompañamiento" en el tema de políticas de Apple y
> Google — ese es el bloque que más espacio ocupa.

---

Hola Alejandra,

Te paso la propuesta completa del módulo de suscripciones, como quedamos. La armé para que la puedas leer sin prisa y decidamos juntos los detalles finales.

La estructuré en 5 bloques:

1. Beneficios por nivel (Free / Gold / Black) — borrador para terminar juntos.
2. Las dos formas limpias de cobrar (IAP vs Stripe) — comparadas sin sesgo.
3. Seguridad y políticas de Apple / Google — lo que más te preocupaba.
4. Cómo encaja en los tiempos, aprovechando la espera de la agencia.
5. Alcance, entregables y propuesta económica.

---

## 1. Beneficios por nivel — borrador para cerrar juntos

Lo dejo a propósito como borrador, no como definitivo. Tú mencionaste que ya tienen ideas de qué va en cada nivel, así que mi propuesta es que la tomes como base y me pases tus adiciones / cambios. Con los dos insumos armo la matriz final.

### Free (puerta de entrada)

**Mi propuesta inicial:**
- Registro completo de pareja con verificación por video.
- Ver el feed de parejas con las mismas reglas que todos (sin limitación de cuántas puede ver).
- Perfil editable, fotos, descripción.
- Filtros básicos: ubicación (km) y rango de edad.
- Máximo **3 solicitudes de mensaje por semana**.
- Travel Match: puede agregar sus propios viajes, pero solo ve matches de los próximos 30 días.
- Notificaciones push básicas (mensajes entrantes).

**Tu parte:** ¿qué otras limitaciones o accesos quieres en Free?

### Gold (el plan core)

**Mi propuesta inicial:**
- Todo lo del Free.
- **Solicitudes de mensaje ilimitadas**.
- **Filtros avanzados completos**: dinámicas, experiencia, intereses, Travel Match sin límite de ventana temporal.
- **Prioridad visual** en el feed de otras parejas Gold/Black (aparece más arriba en las rotaciones).
- Ver quién marcó su perfil o lo guardó (si lo queremos implementar).
- Soporte estándar por correo.

**Tu parte:** ¿qué beneficio específico te imaginas que hace que alguien salte del Free al Gold?

### Black (VIP)

**Mi propuesta inicial:**
- Todo lo del Gold.
- **Badge visible** en la tarjeta del perfil diferenciándolo del resto.
- **Conexión directa con otros Black** sin necesidad de solicitud previa (pueden escribirse de entrada, ambos son Black).
- **Acceso temprano** a nuevos destinos y eventos lifestyle cuando los sumemos.
- **Invitaciones a eventos privados** curados por ustedes.
- **Perfil verificado destacado** (checkmark + borde).
- Soporte prioritario por WhatsApp / Telegram directo con tu equipo.

**Tu parte:** ¿hay un elemento de "círculo cerrado" adicional que quieres reservar solo para Black? (Por ejemplo, un espacio de chat grupal, acceso a recomendaciones curadas, anuncio de eventos presenciales, etc.)

### Precios sugeridos (para discutir)

- **Gold:** USD 14.99 / mes  —  USD 119.99 / año (equivale a ~10 USD/mes, 33% descuento).
- **Black:** USD 39.99 / mes  —  USD 349.99 / año.

Estos rangos están alineados con apps lifestyle comparables (Feeld Majestic $11.99/mes, #Open Premium $14.99/mes). El margen entre Gold y Black es amplio a propósito — el Black no es para todos, es para que quien lo compra sienta exclusividad.

---

## 2. Las dos formas limpias de cobrar

Acá hay solo dos caminos reales. Te los comparo sin sesgo y después te digo cuál recomiendo.

### Camino A — Compra dentro de la app (In-App Purchase de Apple y Google)

**Cómo funciona:** el usuario pulsa "Suscribirme", aparece el selector nativo de Apple / Google, cobra con su método de pago ya asociado al Apple ID / Google Account.

| Aspecto | Detalle |
|---|---|
| Comisión | **30% el primer año**, baja a **15% del año 2 en adelante** (Small Business Program puede bajar a 15% desde el día 1 si tu revenue anual es < USD 1M) |
| Aprobación por stores | **La más fácil**. Apple y Google prefieren este camino. |
| UX | Nativa, ya conocida por usuarios — un tap, huella / Face ID, listo |
| Gestión de suscripciones | La hace Apple/Google — ellos manejan renovación, cancelación, reembolsos |
| Datos de suscriptor | Limitados — no ves correo, tarjeta; solo un receipt ID |
| Integración con panel admin | Más compleja (hay que consultar la API de Apple/Google para validar estado) |

**Ejemplo real:** Tinder Plus, Bumble Premium, Feeld Majestic — todos usan IAP.

### Camino B — Stripe fuera de la app + sincronización

**Cómo funciona:** el usuario ve en la app "Suscribirte", la app abre el navegador a una página web (o un link en Telegram), paga con Stripe (tarjeta / Apple Pay / Google Pay en el navegador). La app consulta periódicamente al servidor y activa los beneficios automáticamente en el próximo inicio de sesión.

| Aspecto | Detalle |
|---|---|
| Comisión | **Stripe: ~2.9% + USD 0.30 por transacción** en LATAM. Comparado con 30% de Apple, la diferencia es enorme. |
| Aprobación por stores | **Permitida pero con reglas estrictas** — hay que respetar Apple Guideline 3.1.3 y Google Play Policy. Lo detallo en la sección 3. |
| UX | Requiere salir de la app una vez (al suscribirse). Para renovaciones, invisible (Stripe cobra solo). |
| Gestión de suscripciones | La haces tú vía panel de Stripe y/o tu panel admin |
| Datos de suscriptor | Completos — correo, historial de pagos, método, geo. Te permite hacer marketing, CRM, análisis |
| Integración con panel admin | Directa — Stripe tiene webhooks a tu backend en tiempo real |

**Ejemplo real:** Netflix, Spotify, Kindle, Disney+ en iOS — todos usan este modelo. El usuario paga fuera (web o landing), entra a la app y ya tiene acceso.

### Mi recomendación

**Camino B (Stripe) como principal, con la opción de agregar IAP solo en iOS si en algún momento vemos que muchos usuarios se van sin suscribirse por la fricción de salir al navegador.**

Motivos:

1. **27% más de margen por suscripción** (vs 30% de Apple en año 1). En un escenario conservador de 200 suscriptores Gold en 6 meses, son ~USD 9.000 que quedan en tu caja en vez de en la de Apple.
2. **Datos del suscriptor** — clave para hacer retention, reactivar bajas, mandar correos, ofrecer descuentos anuales.
3. **Un solo sistema para Affinity + el bot de Telegram** que mencionamos aparte. Los dos corren sobre la misma cuenta Stripe, comparten base de suscriptores, simplifican la contabilidad.
4. **Sin amarre a las stores** — si mañana Apple decide cambiar sus comisiones, no te afecta.

El único costo real del camino B es la fricción de salir al navegador una vez. La podemos mitigar con una pantalla en la app que explique en 2 frases "te llevamos a pagar de forma segura con tarjeta, vuelves en 30 segundos y todo queda activo". Apps mucho más grandes lo hacen así y no se resiente la conversión.

---

## 3. Políticas de Apple y Google — lo que más te preocupaba

Te escribo este bloque con detalle porque entiendo que esta es la parte donde más necesitabas tranquilidad. Voy a ser concreto: hay un camino seguro y hay líneas que **no** se cruzan. Si respetamos el camino seguro, el riesgo de penalización es **bajo**.

### Lo que dice Apple textualmente (Guideline 3.1.3(b) — "Multiplatform Services")

> *"Apps may allow a user to access previously purchased content or subscriptions (specifically: magazines, newspapers, books, audio, music, video, access to professional databases, VoIP, cloud storage, and approved services such as classroom management apps, or person-to-person services), provided that you agree not to directly or indirectly target iOS users to use a purchasing method other than in-app purchase."*

Traducción práctica: la app **puede** reconocer una suscripción comprada fuera, **pero no puede** empujar al usuario a comprarla fuera.

### Lo que significa en la práctica

**✅ Permitido:**
- Tener una pantalla de perfil que diga "Suscripción: Free / Gold / Black".
- Si el usuario está en Free, poner un botón que diga "Upgrade" y lleve a una página web.
- Activar automáticamente los beneficios cuando el usuario se suscribe fuera.
- Mandar un correo al usuario ofreciéndole suscripción (fuera de la app).
- Tener una landing page (`affinity.club/premium`) con la tabla de planes y los precios.

**❌ No permitido dentro de la app iOS:**
- Mostrar precios.
- Poner un botón que diga "Suscríbete por USD 14.99".
- Decir textos como "ahorra un 30% pagando fuera".
- Comparar precios con los de IAP.
- Cualquier banner o pop-up que "presione" a salir.

**Android (Google Play)** es un poco más laxo: sí se pueden mostrar precios dentro de la app y redirigir a web, siempre y cuando no se use Play Billing en paralelo para la misma transacción. Pero por coherencia de código, usaremos la misma regla restrictiva en ambos.

### Apps que usan exactamente este patrón hoy

- **Netflix** — abres la app recién instalada, te dice "no tienes cuenta, visita netflix.com para suscribirte". Ningún precio, ningún botón de pago dentro.
- **Spotify** — igual. Solo login. El upgrade vive en su web.
- **Kindle, Amazon Prime Video, Disney+** — idéntico patrón.
- **Dropbox, Evernote** (planes premium) — suben a la web para el pago, la app solo muestra el estado.

### Nivel de riesgo estimado

- Si respetamos al pie de la letra las dos listas de arriba: **riesgo bajo**. Apple revisa y aprueba apps así cada día.
- Si accidentalmente ponemos precios dentro: **rejection en review** (no es una suspensión de la cuenta, solo rechazan esa versión; se corrige y se reenvía).
- Si además del Stripe ofrecemos IAP dentro: **aprobación más rápida**, y para iOS se convierte en la vía predeterminada. Lo dejo como opción para el futuro.

### Lo que te prometo

Antes de subir a revisión voy a pasar la app por un **check-list de compliance** conmigo mismo — reviso cada pantalla buscando cualquier mención de precio, botón de pago o texto que pueda leerse como "purchase directing". Si algo está al borde, lo cambio. Ya he hecho este proceso con otras apps y sé qué palabras exactas disparan rejections.

---

## 4. Tiempos y cómo encaja con la espera de la agencia

Entendí que la fase 2 de la agencia llega esta semana o la siguiente. Eso nos da una ventana que se aprovecha perfecto — en vez de quedarme quieto, avanzo el backend de suscripciones en paralelo. Así cuando llegue la fase 2 ya tenemos la mitad del trabajo hecho.

### Plan semana por semana

**Semana 1 — Backend sin tocar app (no depende de la agencia)**
- Setup de Stripe (cuenta, productos Gold / Black, webhooks).
- Esquema de base de datos: `subscriptions/{userId}` con plan, estado, vencimiento.
- Cloud Functions: webhook de Stripe, sync de estado, reintentos automáticos en pago fallido.
- Lógica de permisos por plan (decidir qué función está bloqueada para Free).

**Semana 2 — Llega la fase 2 de la agencia; hago integración y paywall**
- Merge del trabajo de la agencia + mis ajustes del feedback actual.
- Pantallas de paywall (comparación de planes).
- Pantalla de "Tu suscripción" en Perfil.
- Landing web pública con Stripe Checkout.

**Semana 3 — Pruebas + subida a stores**
- Prueba end-to-end: compra real de un Gold y un Black con tarjeta de prueba Stripe.
- Validación de que los beneficios se activan dentro de la app al iniciar sesión.
- Check de compliance Apple / Google.
- Submit a App Store y Google Play.

**Semana 4 — Aprobación + ajustes**
- Responder a cualquier feedback del review team.
- Segunda submission si hace falta.

Si la fase 2 de la agencia llega más tarde, los tiempos se corren en paralelo — el backend de suscripciones ya estaría listo, esperando la integración.

---

## 5. Alcance, entregables y parte económica

### Qué incluye este módulo

- Integración con Stripe (cuenta, productos, webhooks, reintentos).
- Backend: Cloud Functions de sync y validación de estado.
- Esquema de base de datos de suscripciones + auditoría.
- Lógica de permisos por plan aplicada a cada feature relevante (solicitudes de mensaje, filtros avanzados, Travel Match, badges).
- Pantallas nativas: paywall, gestión de suscripción propia, badges en perfil.
- Landing web de checkout (página simple, responsive, Stripe Checkout embebido).
- Integración con el panel de administración: ver quién está en cada plan, cuántos suscriptores activos, revenue mensual.
- Check de compliance con políticas de Apple + Google antes de submit.
- Documentación corta de cómo operar el sistema (1 video explicativo).

### Qué NO incluye (para que quede transparente)

- El sistema de monetización del bot de Telegram — va en una propuesta aparte porque son piezas que se integran pero se cobran separado.
- Publicidad paga / marketing de la suscripción — eso es decisión tuya fuera del desarrollo.
- Contenido de marketing del paywall (textos finales, imágenes). Yo entrego los placeholders y tú / tu equipo creativo los terminan.

### Parte económica

**Inversión total del módulo: USD 1.800**

Se divide en 3 hitos para que ninguno de los dos tenga todo el riesgo de un lado:

| Hito | Entregable | Monto | Cuando |
|---|---|---|---|
| 1 | Arranque de desarrollo (setup de Stripe + base de datos + primer commit) | USD 720 (40%) | A la firma — el 40% me permite arrancar con todo el equipo enfocado aquí |
| 2 | Backend funcional — webhook sincronizando estado, lógica de permisos lista, demo interna | USD 540 (30%) | ~10 días después |
| 3 | Suscripción real funcionando end-to-end + app aprobada y lista para stores | USD 540 (30%) | Al cierre del módulo |

Este módulo es **adicional al paquete original de Affinity**. No toca ni modifica las condiciones del contrato que ya tenemos firmado — ese sigue con su propia lógica de entrega final.

---

## Lo que necesito de tu lado para arrancar

1. Tu lectura de la sección 1 — adiciones / cambios a los beneficios de cada nivel.
2. Confirmación de que el camino Stripe (sección 2 + 3) te queda claro y cómodo.
3. OK al plan de trabajo y a la estructura de pagos de la sección 5.
4. Correo para abrir la cuenta de Stripe a tu nombre (el dinero entra directo a tu cuenta bancaria desde el día uno — yo no toco el flujo de pagos).

Con eso firmo propuesta formal y arranco de inmediato. Mientras, sigo con los ajustes de feedback actuales de Affinity en paralelo como quedamos.

Quedo atento a tus comentarios. Sin prisa — prefiero que la leas con calma.

Saludos,
Gabriel
