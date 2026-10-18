#!/bin/zsh
# Builds a release binary and wraps it into build/Screenshot Cleaner.app
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
APP="build/Screenshot Cleaner.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/ScreenshotCleaner "$APP/Contents/MacOS/"
cp .build/release/screenshot-cleaner-mcp "$APP/Contents/MacOS/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Screenshot Cleaner</string>
    <key>CFBundleIdentifier</key><string>com.vatsa.ScreenshotCleaner</string>
    <key>CFBundleExecutable</key><string>ScreenshotCleaner</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSDesktopFolderUsageDescription</key>
    <string>Screenshot Cleaner looks for old screenshots on your Desktop and moves them to the Trash.</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP/Contents/MacOS/screenshot-cleaner-mcp"
codesign --force --sign - "$APP"
echo "Built $APP"
