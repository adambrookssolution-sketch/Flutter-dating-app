# Branding assets

Drop the final PNGs here once the creative team approves them, then re-run:

```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Required files

| File                      | Size       | Purpose                                                                                       |
| ------------------------- | ---------- | --------------------------------------------------------------------------------------------- |
| `icon.png`                | 1024×1024  | Master app icon. Used by both Android (legacy + adaptive fallback) and iOS.                  |
| `icon_foreground.png`     | 1024×1024  | Adaptive-icon foreground (transparent background; design fits inside a 720×720 safe zone).   |
| `splash.png`              | ≥ 1242×1242 | Native splash artwork (logo on white).                                                        |
| `feature_graphic.png`     | 1024×500   | Google Play feature graphic.                                                                  |
| `screenshots/<lang>/<n>.png` | 1290×2796 | App Store screenshots, EN + ES variants.                                                  |

## Conventions

- Brand colour: burgundy `#B31637`
- Motif: pineapple silhouette (lifestyle community symbol)
- All icons must avoid app-name typography that mentions swinger / lifestyle / swap (Apple Store positioning rule)
- Master icon should look correct cropped to a circle (Android) AND a squircle (iOS)
- Keep file size under 1 MB per PNG (`pngquant` recommended before commit)

## Generation gotchas

- Run icon generation BEFORE building any installer; otherwise you get the
  legacy launcher art and the build doesn't pick up changes until full
  rebuild.
- iOS sometimes caches old icons in DerivedData — purge with
  `rm -rf ~/Library/Developer/Xcode/DerivedData` if a refresh is needed.
- Native splash regeneration overwrites `android/app/src/main/res/drawable/launch_background.xml` — review the diff before committing.
