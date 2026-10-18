import XCTest
@testable import CleanerCore

final class CleanerTests: XCTestCase {
    private func shot(_ name: String, bytes: Int64) -> Screenshot {
        Screenshot(url: URL(fileURLWithPath: "/tmp/\(name)"), created: .distantPast, bytes: bytes)
    }

    func testCountsOnlySuccessfulRemovals() {
        let shots = [shot("a", bytes: 10), shot("locked", bytes: 20), shot("c", bytes: 30)]
        struct Locked: Error {}
        let result = Cleaner.trash(shots) { url in
            if url.lastPathComponent == "locked" { throw Locked() }
        }
        XCTAssertEqual(result, Cleaner.Result(count: 2, bytes: 40))
    }

    func testMovesRealFileToTrash() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cleaner-test-\(UUID().uuidString).png")
        try Data("x".utf8).write(to: url)
        var trashed: NSURL?
        defer { if let trashed { try? FileManager.default.removeItem(at: trashed as URL) } }

        let result = Cleaner.trash([Screenshot(url: url, created: .distantPast, bytes: 1)]) { url in
            try FileManager.default.trashItem(at: url, resultingItemURL: &trashed)
        }
        XCTAssertEqual(result.count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}

