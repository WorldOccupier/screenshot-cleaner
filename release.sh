#!/bin/zsh
# Builds a distributable, notarized DMG: build/ScreenshotCleaner-<version>.dmg
#
# One-time setup:
#   1. A "Developer ID Application" certificate in your login keychain
#      (Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application).
#   2. Notary credentials stored in the keychain under the profile name below:
#      xcrun notarytool store-credentials screenshot-cleaner --apple-id <email> --team-id <TEAMID>
#
# Overrides: SIGN_IDENTITY="Developer ID Application: …"  NOTARY_PROFILE=<name>
set -euo pipefail
cd "$(dirname "$0")"

PROFILE="${NOTARY_PROFILE:-screenshot-cleaner}"
IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p' | head -1)}"
if [[ -z "$IDENTITY" ]]; then
  echo "No 'Developer ID Application' certificate found in the keychain." >&2
  exit 1
fi
echo "Signing as: $IDENTITY"

./build.sh
APP="build/Screenshot Cleaner.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG="build/ScreenshotCleaner-$VERSION.dmg"

# Re-sign the ad-hoc build with Developer ID, hardened runtime, and a secure timestamp (all required for notarization).
# Nested code first: the bundled MCP server, then the app around it.
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP/Contents/MacOS/screenshot-cleaner-mcp"
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
codesign --verify --strict --verbose=2 "$APP"

# DMG with the app and an Applications shortcut for drag-to-install.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "Screenshot Cleaner" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
codesign --force --timestamp --sign "$IDENTITY" "$DMG"

echo "Submitting to Apple for notarization (usually a few minutes)…"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"

# Confirm Gatekeeper accepts it the way a downloader's Mac will.
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"
echo "Ready to upload: $DMG"
