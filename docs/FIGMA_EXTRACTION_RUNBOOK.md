# Figma → Affinity Assets — Extraction Runbook

> Internal runbook for the moment the client shares her Figma file.
> The flow is meant to be mechanical: open file, export N layers,
> drop into known paths, run two commands, ship a build.
>
> Target: from "I just got the Figma link" to "client has a new
> APK with finals applied" in **under 60 minutes**.

---

## Step 0 — Sanity check before opening Figma

These environment bits must already be in place:

- Figma desktop app installed and signed in (web works too but
  desktop has a faster export).
- The Affinity repo on `master`, working tree clean.
- `flutter_launcher_icons: ^0.14.1` and `flutter_native_splash: ^2.4.2`
  already in `pubspec.yaml` (verified 2026-04-28).
- `assets/branding/` folder exists with `screenshots/es/`,
  `screenshots/en/`, and `source/` subfolders (verified 2026-04-28).

Run once at the start to confirm:

```bash
ls assets/branding/
# expect: README.md  screenshots/  source/
ls assets/branding/screenshots/
# expect: en/  es/
grep -q "flutter_launcher_icons:" pubspec.yaml && \
grep -q "flutter_native_splash:" pubspec.yaml && \
echo "OK: branding generators wired"
```

---

## Step 1 — What we need from the Figma file

This is the order to extract in. Each row is one Figma export.

| # | Layer / frame to find | Export settings | Drop into | Used for |
|---|-----|-----|-----|-----|
| 1 | App icon master | PNG, **1024×1024**, transparent background OFF (flatten on burgundy or a solid colour) | `assets/branding/icon.png` | Master icon |
| 2 | App icon foreground (motif only, no background) | PNG, **1024×1024**, transparent background ON | `assets/branding/icon_foreground.png` | Adaptive icon foreground |
| 3 | Splash screen art | PNG, **1242×1242** (or the Figma frame's native size if larger), transparent OK | `assets/branding/splash.png` | Native splash |
| 4 | Feature graphic | PNG, **1024×500** | `assets/branding/feature_graphic.png` | Google Play feature graphic |
| 5–9 | App Store screenshots ES — feed, filters, travel match, chat, profile | PNG, **1290×2796** each | `assets/branding/screenshots/es/01_feed.png` … `05_security.png` | App Store ES |
| 10–14 | App Store screenshots EN — same five | PNG, **1290×2796** each | `assets/branding/screenshots/en/01_feed.png` … `05_security.png` | App Store EN |

If the Figma file uses different language names ("Feed de parejas",
"Pantalla de filtros", etc.) — match by content, not by exact name.

---

## Step 2 — Figma export workflow

In Figma desktop:

1. Open the file Alejandra shared.
2. Pin the right sidebar to **Design → Export**.
3. For each frame in the table above:
   - Click the frame.
   - In the Export panel, set Format: PNG, Scale: 1x.
   - Resize the frame to the target size if it isn't already there
     (Figma will warn if cropping happens — match the table).
   - Click "Export <name>".
4. Save the originals into `assets/branding/source/` with their
   Figma layer names so they're traceable for revisions.
5. Then copy / rename into the production paths in the table.

If the design uses vectors / SVGs as source-of-truth, also export
SVG into `assets/branding/source/svg/` for future re-rasterisation.

---

## Step 3 — Generate platform variants

Once `icon.png`, `icon_foreground.png`, and `splash.png` are in place:

```bash
cd d:/app
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

What this writes:

- `android/app/src/main/res/mipmap-*/ic_launcher.png` (Android legacy)
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (adaptive)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (iOS sizes)
- `android/app/src/main/res/drawable*/launch_background.xml` (splash)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png`

**Review the generated files before committing** — sometimes the
foreground gets cropped tighter than expected on Android adaptive,
and the iOS splash sometimes upscales. If anything looks off, the
fix is in the source PNG (not the generator).

---

## Step 4 — Build verification

```bash
cd d:/app
flutter clean
flutter pub get
flutter build apk --debug
```

Open the APK on a device (or just inspect with `apkanalyzer` if
quick), confirm the launcher icon is the new one, and that the splash
shows the new artwork on cold start.

For iOS, this verification needs Xcode + a real device, so I usually
defer it until the client confirms Android visually.

---

## Step 5 — Commit + push

Single commit, message template:

```
chore(branding): integrate Figma assets from creative team

Source extracted from <date> Figma file shared by Alejandra:
  - assets/branding/icon.png             — 1024×1024 master
  - assets/branding/icon_foreground.png  — adaptive foreground
  - assets/branding/splash.png           — splash artwork
  - assets/branding/feature_graphic.png  — Google Play
  - assets/branding/screenshots/es/01..05.png  — App Store ES
  - assets/branding/screenshots/en/01..05.png  — App Store EN

Generated variants via flutter_launcher_icons + flutter_native_splash;
android/ and ios/ trees updated accordingly.
```

The CI pipeline picks this up and the next APK build has the new
identity baked in.

---

## Step 6 — What to send the client immediately

Within an hour of receiving the Figma link, ship back:

1. A screenshot of the new launcher icon on Android (just the home
   screen with the icon).
2. A screenshot of the new splash on cold start.
3. A short note in the same Spanish tone we've been using:

   > *"Listo, ya integré los assets que pasaste. Te dejo capturas
   > del ícono y la splash en Android. Cualquier detalle visual
   > que quieras ajustar, mándame y lo corrijo."*

That speed is the point — the client tests for "is this dev
actually fast" and an hour-long round-trip is the strongest answer.

---

## Common pitfalls

- **Figma layer is locked**: ask Alejandra for view + export
  permission, not edit. Edit isn't needed.
- **Figma frame slightly off-size** (1023 instead of 1024): export
  at 1x, then resize the resulting PNG with ImageMagick:
  `convert in.png -resize 1024x1024 out.png` or just skip — Flutter
  generators tolerate ±2px.
- **Foreground has accidental shadow / glow extending past the safe
  zone**: Android adaptive will crop it on circle masks. Either ask
  for a cleaner export or accept the slight crop.
- **Apple flags the icon for "purchasing" iconography**: rare but
  possible. The pineapple is fine; problems would come from text
  in the icon (banned). If the icon contains any wordmark, ask for
  a no-text variant before proceeding.

---

## When the screenshots arrive

App Store / Google Play screenshots aren't part of the icon flow —
they get uploaded to App Store Connect and Play Console at submission
time, not into the binary. No code change needed; just check sizes
match the table above and place them in the right folder.

---

**End of runbook.**
