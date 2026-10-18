import Foundation

/// A minimal MCP server: JSON-RPC 2.0, one message per line, exposing only tools.
public final class MCPServer {
    static let supportedVersions = ["2025-06-18", "2025-03-26", "2024-11-05"]
    static let instructions = "Start with screenshots_summary (one line). List only when file names are needed."

    private let tools: ScreenshotTools

    public init(tools: ScreenshotTools) {
        self.tools = tools
    }

    /// Handles one incoming line. Returns the reply line, or nil when none is due (notifications, responses).
    public func handle(_ line: Data) -> Data? {
        guard let message = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any] else {
            return encode(id: NSNull(), error: .parse)
        }
        let id = message["id"]
        guard let method = message["method"] as? String else {
            return id == nil ? nil : encode(id: id!, error: .invalidRequest)
        }
        guard let id else { return nil } // notification, e.g. notifications/initialized
        do {
            return encode(["jsonrpc": "2.0", "id": id, "result": try respond(to: method, params: message["params"] as? [String: Any] ?? [:])])
        } catch let error as RPCError {
            return encode(id: id, error: error)
        } catch {
            return encode(id: id, error: RPCError(code: -32603, message: "\(error)"))
        }
    }

    private func respond(to method: String, params: [String: Any]) throws -> [String: Any] {
        switch method {
        case "initialize":
            let requested = params["protocolVersion"] as? String ?? ""
            return [
                "protocolVersion": Self.supportedVersions.contains(requested) ? requested : Self.supportedVersions[0],
                "capabilities": ["tools": [String: Any]()],
                "serverInfo": ["name": "screenshot-cleaner", "version": "0.1.0"],
                "instructions": Self.instructions,
            ]
        case "ping":
            return [:]
        case "tools/list":
            return ["tools": tools.definitions]
        case "tools/call":
            guard let name = params["name"] as? String else { throw RPCError.invalidParams("Missing tool name") }
            let reply = try tools.call(name, arguments: params["arguments"] as? [String: Any] ?? [:])
            return ["content": [["type": "text", "text": reply.text]], "isError": reply.isError]
        default:
            throw RPCError(code: -32601, message: "Method not found: \(method)")
        }
    }

    private func encode(id: Any, error: RPCError) -> Data? {
        encode(["jsonrpc": "2.0", "id": id, "error": ["code": error.code, "message": error.message]])
    }

    private func encode(_ object: [String: Any]) -> Data? {
        try? JSONSerialization.data(withJSONObject: object, options: [.withoutEscapingSlashes, .sortedKeys])
    }
}

struct RPCError: Error, Equatable {
    let code: Int
    let message: String

    static let parse = RPCError(code: -32700, message: "Parse error")
    static let invalidRequest = RPCError(code: -32600, message: "Invalid request")
    static func invalidParams(_ message: String) -> RPCError { RPCError(code: -32602, message: message) }
}
