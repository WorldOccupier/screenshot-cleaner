#!/bin/zsh
# Builds a Developer ID signed, notarized and stapled app and zips it for install.sh:
#   build/ScreenshotCleaner.zip and build/ScreenshotCleaner.zip.sha256
# Pass --upload to replace those assets on the GitHub release matching the app's version.
#
# Same one-time setup as release.sh: a "Developer ID Application" certificate and notary credentials:
#   xcrun notarytool store-credentials screenshot-cleaner --apple-id <email> --team-id <TEAMID>
#
# Or skip the keychain and pass an App Store Connect API key (Team Keys) directly:
#   NOTARY_KEY=~/AuthKey_XXXXXXXXXX.p8 NOTARY_ISSUER=<issuer id> ./notarize-zip.sh
# The key ID is read from the file name; set NOTARY_KEY_ID if it was renamed.
#
# Overrides: SIGN_IDENTITY="Developer ID Application: …"  NOTARY_PROFILE=<name>
set -euo pipefail
cd "$(dirname "$0")"

if [[ -n "${NOTARY_KEY:-}" ]]; then
  KEY_ID="${NOTARY_KEY_ID:-${${NOTARY_KEY:t:r}#AuthKey_}}"
  AUTH=(--key "$NOTARY_KEY" --key-id "$KEY_ID" --issuer "${NOTARY_ISSUER:?NOTARY_ISSUER is required with NOTARY_KEY}")
else
  AUTH=(--keychain-profile "${NOTARY_PROFILE:-screenshot-cleaner}")
fi
# Check the notary credentials before spending time on a build.
if ! xcrun notarytool history "${AUTH[@]}" >/dev/null; then
  echo "Apple rejected the notary credentials." >&2
  exit 1
fi

IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p' | head -1)}"
if [[ -z "$IDENTITY" ]]; then
  echo "No 'Developer ID Application' certificate found in the keychain." >&2
  exit 1
fi
echo "Signing as: $IDENTITY"

./build.sh
APP="build/Screenshot Cleaner.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
ZIP=build/ScreenshotCleaner.zip

# Re-sign the ad-hoc build with Developer ID, hardened runtime, and a secure timestamp (all required for notarization).
# Nested code first: the bundled MCP server, then the app around it.
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP/Contents/MacOS/screenshot-cleaner-mcp"
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
codesign --verify --strict --verbose=2 "$APP"

# notarytool only accepts a zip, but the ticket is stapled to the app, so the zip is rebuilt after stapling.
rm -f "$ZIP" "$ZIP.sha256"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "Submitting to Apple for notarization (usually a few minutes)…"
RESULT=$(xcrun notarytool submit "$ZIP" "${AUTH[@]}" --wait --output-format json)
STATUS=$(plutil -extract status raw -o - - <<< "$RESULT")
if [[ "$STATUS" != "Accepted" ]]; then
  echo "Notarization finished with status: $STATUS" >&2
  xcrun notarytool log "$(plutil -extract id raw -o - - <<< "$RESULT")" "${AUTH[@]}" >&2
  exit 1
fi
xcrun stapler staple "$APP"

# Confirm Gatekeeper accepts it the way a downloader's Mac will.
spctl --assess --type execute --verbose=2 "$APP"

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
(cd build && shasum -a 256 ScreenshotCleaner.zip > ScreenshotCleaner.zip.sha256)

if [[ "${1:-}" == "--upload" ]]; then
  gh release upload "v$VERSION" "$ZIP" "$ZIP.sha256" --clobber
  echo "Uploaded to release v$VERSION"
else
  echo "Ready to upload: $ZIP and $ZIP.sha256 (or rerun with --upload)"
fi
