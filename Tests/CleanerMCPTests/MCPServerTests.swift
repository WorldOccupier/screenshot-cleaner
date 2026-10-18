import XCTest
@testable import CleanerMCP

final class MCPServerTests: XCTestCase {
    private var server: MCPServer!

    override func setUp() {
        let folder = FileManager.default.temporaryDirectory
        server = MCPServer(tools: ScreenshotTools(folder: folder, defaultAgeDays: 7, remove: { _ in XCTFail("nothing to remove") }))
    }

    private func send(_ json: String) throws -> [String: Any]? {
        guard let reply = server.handle(Data(json.utf8)) else { return nil }
        XCTAssertFalse(reply.contains(UInt8(ascii: "\n")), "one message per line")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: reply) as? [String: Any])
    }

    func testInitializeEchoesSupportedVersionAndAdvertisesTools() throws {
        let reply = try XCTUnwrap(send(#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}"#))
        XCTAssertEqual(reply["id"] as? Int, 1)
        let result = try XCTUnwrap(reply["result"] as? [String: Any])
        XCTAssertEqual(result["protocolVersion"] as? String, "2025-03-26")
        XCTAssertNotNil((result["capabilities"] as? [String: Any])?["tools"])
        XCTAssertEqual((result["serverInfo"] as? [String: Any])?["name"] as? String, "screenshot-cleaner")
    }

    func testNotificationsGetNoReply() throws {
        XCTAssertNil(try send(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#))
    }

    func testToolCallWrapsTextContent() throws {
        let reply = try XCTUnwrap(send(#"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"screenshots_summary","arguments":{}}}"#))
        let result = try XCTUnwrap(reply["result"] as? [String: Any])
        let content = try XCTUnwrap(result["content"] as? [[String: Any]])
        XCTAssertEqual(content.first?["type"] as? String, "text")
        XCTAssertTrue((content.first?["text"] as? String ?? "").isEmpty == false)
        XCTAssertEqual(result["isError"] as? Bool, false)
    }
}
