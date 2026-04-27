# Affinity — Especificación de assets para el equipo creativo

> Lista exacta de los archivos visuales que el equipo creativo debe
> producir para que la app pueda subirse a las tiendas. Para que
> puedan trabajar en paralelo a lo que estoy terminando del lado
> técnico, sin tener que esperarme.
>
> Cualquier archivo se entrega como **PNG sin transparencia para iOS**
> y **PNG con o sin transparencia para Android**, en los tamaños
> exactos que se piden abajo.

---

## 1. Ícono de la app — el más crítico

### Especificaciones técnicas

- **Tamaño base:** 1024 × 1024 px
- **Formato:** PNG, fondo opaco (sin canal alfa para iOS)
- **Espacio de color:** sRGB
- **Sin esquinas redondeadas** — los sistemas operativos las aplican solos
- **Sin texto** dentro del ícono (ni "Affinity" ni "A") — Apple lo
  flagga como "ícono que parece logo de marca dentro de un cuadro"

### Lineamiento visual sugerido

- Motivo principal: la **piña dorada** que ya estamos usando en la app
- Fondo: gradiente burgundy → púrpura (los colores de marca:
  `#B31637` → `#5B1280`) o burgundy sólido
- La piña debe ocupar el 60–70% del cuadro (no llenar al borde)
- Ningún texto

### Variantes derivadas

Una vez tengamos el master de 1024 × 1024, yo genero todas las
variantes derivadas automáticamente con `flutter_launcher_icons`. Es
decir: el equipo creativo entrega **un solo archivo**, yo me encargo
del resto.

---

## 2. Splash screen — la pantalla de carga

### Especificaciones técnicas

- **Tamaño base:** 1242 × 2688 px (iPhone más grande, escalable)
- **Formato:** PNG
- **Fondo:** un solo color sólido — sugiero burgundy `#B31637` o
  blanco
- **Centro:** la piña en versión simplificada (puede ser misma del
  ícono, o una versión más limpia sin gradiente)

### Lineamiento

- La splash dura 1–2 segundos al abrir la app
- Debe sentirse como continuación visual del ícono
- Mucho aire alrededor del símbolo central

---

## 3. Capturas de pantalla para las tiendas

Esto es lo que ven los usuarios cuando navegan App Store o Google
Play. **5 capturas por idioma (español + inglés) por cada tamaño de
dispositivo.**

### Tamaños obligatorios

| Tienda | Dispositivo | Tamaño |
|---|---|---|
| App Store | iPhone 6.7" (Pro Max) | 1290 × 2796 |
| App Store | iPhone 6.5" | 1242 × 2688 |
| App Store | iPhone 5.5" | 1242 × 2208 |
| Google Play | Phone | mínimo 1080 × 1920 |
| Google Play | Tablet 7" | 1200 × 1920 |
| Google Play | Tablet 10" | 1800 × 2560 |

### Las 5 capturas (mismo orden, en ambos idiomas)

| # | Pantalla | Texto sobreimpuesto (ES) | Texto (EN) |
|---|----------|--------------------------|------------|
| 1 | Feed de parejas con piña arriba | Descubre parejas verificadas | Discover verified couples |
| 2 | Pantalla de filtros | Filtros que van con tu vibra | Filters that match your vibe |
| 3 | Travel Match | Coinciden en el viaje | Meet on the way |
| 4 | Chat / vista de mensaje | Conversaciones que importan | Conversations that matter |
| 5 | Perfil con seguridad | Privacidad de base | Privacy built in |

### Plantilla de diseño sugerida

Cada captura debe tener:
- Fondo de color de marca (burgundy o gradiente)
- Mockup de un teléfono real con el screenshot de la app dentro
- El texto sobreimpuesto arriba o abajo, con tipografía limpia
- El logo pequeño de la app en una esquina

Las capturas reales del feed, filtros, etc. se las paso yo en cuanto
me confirmen el visual general; el equipo creativo no tiene que
recrear las pantallas de la app, solo enmarcarlas.

---

## 4. Feature graphic — solo Google Play

- **Tamaño:** 1024 × 500 px
- **Formato:** PNG o JPG
- **Contenido:** banner que aparece en la página de la app en Google
  Play. Suele incluir el logo + un eslogan corto como "Una comunidad
  para parejas auténticas" + algún elemento gráfico de marca (la
  piña, una pareja, etc.)

---

## 5. Lo que NO necesitamos del equipo creativo

Para que no pierdan tiempo en cosas que no son críticas:

- **NO** se necesita una landing web ahora — la haré yo después
  para el módulo de suscripciones, con base en el sistema visual
  del ícono y la splash.
- **NO** se necesitan ilustraciones para el onboarding interno
  de la app — la app actual no usa ilustraciones, y el cambio
  visual ahora retrasaría todo.
- **NO** se necesitan animaciones Lottie — la primera versión va
  sin animaciones complejas para mantener el rendimiento.

---

## 6. Tiempos sugeridos

Si el equipo arranca esta semana:

| Día | Entregable |
|-----|------------|
| 1–2 | Ícono master 1024×1024 |
| 3 | Splash screen |
| 4–6 | Las 5 capturas en ES + EN |
| 7 | Feature graphic Google Play |

Eso te deja con todos los assets listos en una semana, en paralelo
a que se aprueben las cuentas de desarrollador (Apple toma 3–10
días, Google Play minutos).

---

## 7. Cómo se entregan a mí

Un solo Google Drive (o Dropbox / WeTransfer) con la estructura:

```
Affinity Assets/
├── icon/
│   └── icon_1024.png
├── splash/
│   └── splash_1242x2688.png
├── screenshots/
│   ├── es/
│   │   ├── 01_feed.png
│   │   ├── 02_filters.png
│   │   ├── 03_travel.png
│   │   ├── 04_chat.png
│   │   └── 05_security.png
│   └── en/
│       └── (los mismos 5)
└── google_play_feature/
    └── feature_1024x500.png
```

Yo me encargo de:
- Generar las variantes pequeñas del ícono (16×16 hasta 180×180).
- Comprimir y optimizar cada captura para subir a la tienda sin
  pérdida visible.
- Subirlas a App Store Connect y Google Play Console.

---

## 8. Resumen accionable para el equipo creativo

**Lo que necesito producido, en orden de prioridad:**

- [ ] Ícono master 1024 × 1024 PNG (si solo pueden hacer una cosa, esta)
- [ ] Splash screen PNG
- [ ] 10 capturas (5 ES + 5 EN) con sus mockups de teléfono
- [ ] Feature graphic Google Play 1024 × 500

Cualquier dirección creativa diferente a la sugerida (otros colores,
otro símbolo distinto a la piña, otra tipografía) **es bienvenida**
— solo necesito que sea coherente entre todos los entregables.

Cualquier duda durante el diseño, me mandan WhatsApp y respondo en
el momento.
