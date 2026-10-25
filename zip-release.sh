#!/bin/zsh
# Builds the ad-hoc signed app and zips it for install.sh:
#   build/ScreenshotCleaner.zip and build/ScreenshotCleaner.zip.sha256
# Upload both files to the release; install.sh verifies the download against the checksum.
set -euo pipefail
cd "$(dirname "$0")"

./build.sh
rm -f build/ScreenshotCleaner.zip build/ScreenshotCleaner.zip.sha256
ditto -c -k --keepParent "build/Screenshot Cleaner.app" build/ScreenshotCleaner.zip
(cd build && shasum -a 256 ScreenshotCleaner.zip > ScreenshotCleaner.zip.sha256)
echo "Ready to upload: build/ScreenshotCleaner.zip and build/ScreenshotCleaner.zip.sha256"
