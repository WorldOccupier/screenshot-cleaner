#!/bin/zsh
# Builds a release binary and wraps it into build/Screenshot Cleaner.app
set -euo pipefail
cd "$(dirname "$0")"

plutil -lint Resources/Info.plist >/dev/null

# Universal binary, so it runs on Apple Silicon and Intel Macs.
swift build -c release --arch arm64 --arch x86_64
BIN=.build/apple/Products/Release
APP="build/Screenshot Cleaner.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/ScreenshotCleaner" "$APP/Contents/MacOS/"
cp "$BIN/screenshot-cleaner-mcp" "$APP/Contents/MacOS/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
# Resources/Info.plist is the single source for the bundle id and version.
cp Resources/Info.plist "$APP/Contents/Info.plist"

codesign --force --sign - "$APP/Contents/MacOS/screenshot-cleaner-mcp"
codesign --force --sign - "$APP"
echo "Built $APP"
