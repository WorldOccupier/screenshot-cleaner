// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "ScreenshotCleaner",
    platforms: [.macOS(.v14)],
    targets: [
        // Pure logic: scanning, filtering, cleaning, auto-clean policy, deck motion. No UI.
        .target(name: "CleanerCore"),
        // App state, services (folder watching, heartbeat, thumbnails, scroll input), views, menu bar icon.
        .target(name: "ScreenshotCleanerUI", dependencies: ["CleanerCore"]),
        // Entry point only.
        .executableTarget(name: "ScreenshotCleaner", dependencies: ["ScreenshotCleanerUI"]),
        .testTarget(name: "CleanerCoreTests", dependencies: ["CleanerCore"]),
        .testTarget(name: "ScreenshotCleanerUITests", dependencies: ["ScreenshotCleanerUI", "CleanerCore"]),
    ]
)
