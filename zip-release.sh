#!/bin/zsh
# Builds the ad-hoc signed app and zips it for install.sh: build/ScreenshotCleaner.zip
set -euo pipefail
cd "$(dirname "$0")"

./build.sh
rm -f build/ScreenshotCleaner.zip
ditto -c -k --keepParent "build/Screenshot Cleaner.app" build/ScreenshotCleaner.zip
echo "Ready to upload: build/ScreenshotCleaner.zip"
