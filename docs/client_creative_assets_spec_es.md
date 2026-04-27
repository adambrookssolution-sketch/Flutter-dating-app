# Affinity — Especificación de assets para el equipo creativo

> Lista de los archivos visuales que vamos a necesitar para subir la
> app a las tiendas. Para que el equipo creativo pueda trabajar en
> paralelo y no quede como bloqueo al final.

---

## Ícono de la app

Es la pieza más crítica.

- Tamaño base: 1024 × 1024 px
- Formato: PNG, fondo opaco (sin canal alfa para iOS)
- Espacio de color: sRGB
- Sin esquinas redondeadas (los sistemas operativos las aplican solos)
- Sin texto dentro (Apple flagga los íconos que parecen logos de marca dentro de un cuadro)

Sobre el lineamiento visual, sugiero el motivo de la piña dorada que ya estamos usando, sobre un fondo en gradiente burgundy (#B31637) hacia púrpura (#5B1280) o burgundy sólido. La piña debería ocupar entre el 60 y el 70 por ciento del cuadro. Cualquier dirección distinta también funciona, lo importante es que sea coherente con la splash y las capturas.

Una vez tengamos el master de 1024 × 1024, yo genero todas las variantes derivadas (16×16 hasta 180×180) automáticamente con flutter_launcher_icons. El equipo creativo solo entrega un archivo.

---

## Splash screen

La pantalla que aparece 1-2 segundos al abrir la app.

- Tamaño base: 1242 × 2688 px (iPhone más grande, escalable)
- Formato: PNG
- Fondo: un color sólido. Sugiero burgundy o blanco.
- Centro: la piña en versión simplificada (puede ser la misma del ícono o una más limpia sin gradiente).

La idea es que la splash se sienta como continuación visual del ícono.

---

## Capturas de pantalla para las tiendas

Esto es lo que ven los usuarios cuando navegan App Store o Google Play. Cinco capturas por idioma (español + inglés) por cada tamaño de dispositivo.

Tamaños obligatorios:

- App Store iPhone 6.7" (Pro Max): 1290 × 2796
- App Store iPhone 6.5": 1242 × 2688
- App Store iPhone 5.5": 1242 × 2208
- Google Play Phone: mínimo 1080 × 1920
- Google Play Tablet 7": 1200 × 1920
- Google Play Tablet 10": 1800 × 2560

Las cinco capturas, en el mismo orden en ambos idiomas:

1. Feed de parejas con la piña arriba — texto: "Descubre parejas verificadas" / "Discover verified couples"
2. Pantalla de filtros — "Filtros que van con tu vibra" / "Filters that match your vibe"
3. Travel Match — "Coinciden en el viaje" / "Meet on the way"
4. Chat o vista de mensaje — "Conversaciones que importan" / "Conversations that matter"
5. Perfil con seguridad — "Privacidad de base" / "Privacy built in"

Cada captura debe tener un fondo de color de marca, un mockup de un teléfono real con el screenshot adentro, el texto sobreimpuesto arriba o abajo con tipografía limpia, y el logo pequeño en una esquina. Los screenshots reales del feed, filtros y demás los paso yo cuando me confirmes la dirección visual general — el equipo creativo no tiene que recrear las pantallas, solo enmarcarlas.

---

## Feature graphic — solo para Google Play

- Tamaño: 1024 × 500 px
- Formato: PNG o JPG

Es el banner que aparece en la página de la app en Google Play. Suele incluir el logo, un eslogan corto ("Una comunidad para parejas auténticas" o algo similar), y algún elemento gráfico de marca.

---

## Tiempos sugeridos

Si el equipo arranca esta semana:

- Días 1 y 2: ícono master 1024 × 1024
- Día 3: splash
- Días 4 a 6: las cinco capturas en español e inglés
- Día 7: feature graphic

Una semana cómoda, en paralelo a que se aprueben las cuentas de desarrollador.

---

## Cómo me llega todo

Un solo Google Drive (o Dropbox o WeTransfer) con esta estructura:

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
│       └── (las mismas 5)
└── google_play_feature/
    └── feature_1024x500.png
```

Yo me encargo del resto: generar las variantes pequeñas del ícono, comprimir cada captura para que suba a la tienda sin pérdida visible, y subirlas a App Store Connect y Google Play Console.

---

## En orden de prioridad, lo que necesito producido

1. Ícono master 1024 × 1024 (si solo pueden hacer una cosa, esta).
2. Splash screen.
3. Las 10 capturas (5 en español, 5 en inglés).
4. Feature graphic de Google Play.

Cualquier dirección creativa diferente a la sugerida (otro símbolo distinto a la piña, otra paleta, otra tipografía) es bienvenida. Lo único que pediría es que sea coherente entre todos los entregables.

Cualquier duda durante el diseño, mándame WhatsApp.
