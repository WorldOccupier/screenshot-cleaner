# Screenshot Cleaner

A tiny macOS menu bar app that clears old screenshots off your Desktop.

<p align="center"><img src="docs/screenshot.png" width="412" alt="Screenshot Cleaner popover"></p>

- **Finds screenshots** in the folder macOS saves them to (Desktop by default), and nothing else.
- **Pick an age** (any, 1 day, 1 week, 1 month) and flick through the stack to see what will go.
- **Move to Trash** in one click. Files are never deleted outright, so anything can be restored.
- **Auto-clean** once a day, if you turn it on. It never touches screenshots from the last 24 hours.

## MCP server for agents

The app bundles an [MCP](https://modelcontextprotocol.io) server so coding agents can tidy screenshots in a few tokens instead of listing and moving files themselves.

| Tool | Returns |
|---|---|
| `screenshots_summary` | One line: `~/Desktop: 14 screenshots, 52 MB. 9 older than 7 days (38 MB), oldest 2026-08-02.` |
| `list_screenshots` | Date, size and name per line, oldest first, capped by `limit` |
| `clean_screenshots` | Moves to the Trash by `older_than_days` and/or `files`; never runs without one |

Same detection and safety as the app: only screenshots in the macOS screenshot folder, always to the Trash. The default age is whatever you picked in the app.

```sh
claude mcp add screenshot-cleaner -- "/Applications/Screenshot Cleaner.app/Contents/MacOS/screenshot-cleaner-mcp"
```

Other clients: run that binary as a stdio server. From source it's `.build/release/screenshot-cleaner-mcp`.

## Build

Requires macOS 14+ and Xcode 16 (Swift 6 toolchain).

```sh
./build.sh                         # builds "build/Screenshot Cleaner.app"
open "build/Screenshot Cleaner.app"
swift test                         # run the tests
```

`release.sh` signs with a Developer ID certificate, notarizes and staples a DMG for distribution.
