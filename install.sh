#!/bin/sh
# Installs the latest Screenshot Cleaner into /Applications.
# curl downloads aren't quarantined, so the app opens without notarization.
set -eu

URL="https://github.com/WorldOccupier/screenshot-cleaner/releases/latest/download/ScreenshotCleaner.zip"
APP="/Applications/Screenshot Cleaner.app"

echo "Downloading Screenshot Cleaner…"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$URL" -o "$TMP/app.zip"
ditto -x -k "$TMP/app.zip" "$TMP"

pkill -x ScreenshotCleaner 2>/dev/null || true
rm -rf "$APP"
mv "$TMP/Screenshot Cleaner.app" "$APP"
open "$APP"
echo "Installed. Look for the stack of cards in your menu bar."
