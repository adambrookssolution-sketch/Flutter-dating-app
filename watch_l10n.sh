#!/bin/bash
# Watches ARB files and runs flutter gen-l10n on every save.
# Requires inotify-tools: sudo apt install inotify-tools
#
# Usage: ./watch_l10n.sh

ARB_DIR="$(dirname "$0")/lib/l10n"

echo "Watching $ARB_DIR for changes..."

inotifywait -m -e close_write --include '.*\.arb$' "$ARB_DIR" |
while read -r _dir _event file; do
  echo "[$file saved] Running flutter gen-l10n..."
  flutter gen-l10n --project-dir "$(dirname "$0")"
  echo "Done."
done
