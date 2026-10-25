import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import ScreenshotCleanerUI

final class ThumbnailLoaderTests: XCTestCase {
    private var url: URL!

    override func setUpWithError() throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("thumb-\(UUID().uuidString).png")
        try writeImage(red: 1, green: 0, blue: 0)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: url)
    }

    func testSameFileAndSizeComeFromTheCache() async throws {
        let first = try await load(maxPixels: 16)
        let second = try await load(maxPixels: 16)
        XCTAssertTrue(first === second, "the second load should be the cached instance")
    }

    func testReplacingTheFileInvalidatesTheCache() async throws {
        let first = try await load(maxPixels: 16)
        try writeImage(red: 0, green: 0, blue: 1)
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(60)], ofItemAtPath: url.path
        )

        let second = try await load(maxPixels: 16)
        XCTAssertFalse(first === second, "a replaced file must be decoded again")
    }

    func testDifferentPixelSizesAreCachedSeparately() async throws {
        let small = try await load(maxPixels: 8)
        let large = try await load(maxPixels: 32)
        XCTAssertFalse(small === large)
    }

    private func load(maxPixels: CGFloat) async throws -> CGImage {
        let image = await ThumbnailLoader.load(url, maxPixels: maxPixels)
        return try XCTUnwrap(image)
    }

    private func writeImage(red: CGFloat, green: CGFloat, blue: CGFloat) throws {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        let image = try XCTUnwrap(context.makeImage())

        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil
        ))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }
}
