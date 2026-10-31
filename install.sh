#!/bin/sh
# Installs the latest Screenshot Cleaner into Applications.
# The app is Developer ID signed and notarized; the published checksum guards the download.
set -eu

URL="https://github.com/WorldOccupier/screenshot-cleaner/releases/latest/download/ScreenshotCleaner.zip"
NAME="Screenshot Cleaner.app"

if [ -w /Applications ]; then
  DEST="/Applications/$NAME"
else
  mkdir -p "$HOME/Applications"
  DEST="$HOME/Applications/$NAME"
fi

echo "Downloading Screenshot Cleaner…"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL --proto '=https' --tlsv1.2 "$URL" -o "$TMP/app.zip"

# The checksum is published beside the zip. Releases made before it existed don't have one;
# warn rather than breaking those installs.
if curl -fsSL --proto '=https' --tlsv1.2 "$URL.sha256" -o "$TMP/app.zip.sha256" 2>/dev/null; then
  expected=$(awk 'NR == 1 { print $1 }' "$TMP/app.zip.sha256")
  actual=$(shasum -a 256 "$TMP/app.zip" | awk '{ print $1 }')
  if [ "$expected" != "$actual" ]; then
    echo "Checksum mismatch: the download is corrupted or was tampered with. Nothing was installed." >&2
    exit 1
  fi
  echo "Checksum verified."
else
  echo "Warning: couldn't download a checksum for this release; skipping verification." >&2
fi

ditto -x -k "$TMP/app.zip" "$TMP"
if [ ! -d "$TMP/$NAME" ]; then
  echo "The download did not contain $NAME. Nothing was installed." >&2
  exit 1
fi

pkill -x ScreenshotCleaner 2>/dev/null || true
rm -rf "$DEST"
mv "$TMP/$NAME" "$DEST"
open "$DEST"
echo "Installed to $DEST. Look for the stack of cards in your menu bar."
