// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "ScreenshotCleaner",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ScreenshotCleaner", targets: ["ScreenshotCleaner"]),
        .executable(name: "screenshot-cleaner-mcp", targets: ["ScreenshotCleanerMCP"]),
    ],
    targets: [
        // Pure logic: scanning, filtering, cleaning, auto-clean policy, deck motion. No UI.
        .target(name: "CleanerCore"),
        // App state, services (folder watching, heartbeat, thumbnails, scroll input), views, menu bar icon.
        .target(name: "ScreenshotCleanerUI", dependencies: ["CleanerCore"]),
        // Entry point only.
        .executableTarget(name: "ScreenshotCleaner", dependencies: ["ScreenshotCleanerUI"]),
        // MCP server for agents: JSON-RPC handling and the screenshot tools, with compact text replies.
        .target(name: "CleanerMCP", dependencies: ["CleanerCore"]),
        // stdio entry point for the MCP server.
        .executableTarget(name: "ScreenshotCleanerMCP", dependencies: ["CleanerMCP"]),
        .testTarget(name: "CleanerCoreTests", dependencies: ["CleanerCore"]),
        .testTarget(name: "ScreenshotCleanerUITests", dependencies: ["ScreenshotCleanerUI", "CleanerCore"]),
        .testTarget(name: "CleanerMCPTests", dependencies: ["CleanerMCP", "CleanerCore"]),
    ]
)
