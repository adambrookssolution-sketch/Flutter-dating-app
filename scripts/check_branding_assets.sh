#!/usr/bin/env bash
# Quick verifier — call after dropping the Figma exports into
# assets/branding/ to confirm every required file is present at the
# expected path. Exits non-zero if anything is missing so you can
# wire it into a pre-commit hook later.
#
# Usage:
#   ./scripts/check_branding_assets.sh
#
# Output:
#   ✓ for files present at the right path
#   ✗ for files missing — followed by the spec from FIGMA_EXTRACTION_RUNBOOK.md

set -u

PROJECT_ROOT=$(dirname "$(dirname "$(readlink -f "$0")")")
BRANDING="$PROJECT_ROOT/assets/branding"
MISSING=0

check() {
  local path="$1"
  local desc="$2"
  if [ -f "$BRANDING/$path" ]; then
    local size
    size=$(stat -c %s "$BRANDING/$path" 2>/dev/null || echo "?")
    echo "  ✓ $path  ($size bytes — $desc)"
  else
    echo "  ✗ $path  MISSING — $desc"
    MISSING=$((MISSING + 1))
  fi
}

echo "Affinity branding asset check — $BRANDING"
echo
echo "Master assets:"
check "icon.png" "1024×1024 master app icon"
check "icon_foreground.png" "1024×1024 adaptive foreground (transparent BG)"
check "splash.png" "≥1242×1242 native splash"
check "feature_graphic.png" "1024×500 Google Play feature graphic"

echo
echo "App Store screenshots — Spanish:"
for n in 01_feed 02_filters 03_travel 04_chat 05_security; do
  check "screenshots/es/${n}.png" "1290×2796 — Spanish App Store"
done

echo
echo "App Store screenshots — English:"
for n in 01_feed 02_filters 03_travel 04_chat 05_security; do
  check "screenshots/en/${n}.png" "1290×2796 — English App Store"
done

echo
if [ "$MISSING" -eq 0 ]; then
  echo "All 14 branding assets in place. Ready to run:"
  echo "  dart run flutter_launcher_icons"
  echo "  dart run flutter_native_splash:create"
  exit 0
else
  echo "$MISSING asset(s) missing — see FIGMA_EXTRACTION_RUNBOOK.md for the spec."
  exit 1
fi
