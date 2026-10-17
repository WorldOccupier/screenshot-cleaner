# Screenshot Cleaner

A tiny macOS menu bar app that clears old screenshots off your Desktop.

<p align="center"><img src="docs/screenshot.png" width="412" alt="Screenshot Cleaner popover"></p>

- **Finds screenshots** in the folder macOS saves them to (Desktop by default): screenshots and screen recordings, nothing else.
- **Pick an age** (any, 1 day, 1 week, 1 month) and flick through the stack to see what will go.
- **Move to Trash** in one click. Files are never deleted outright, so anything can be restored.
- **Auto-clean** once a day, if you turn it on. It never touches screenshots from the last 24 hours.

## Build

Requires macOS 14+ and Xcode 16 (Swift 6 toolchain).

```sh
./build.sh                         # builds "build/Screenshot Cleaner.app"
open "build/Screenshot Cleaner.app"
swift test                         # run the tests
```

`release.sh` signs with a Developer ID certificate, notarizes and staples a DMG for distribution.
