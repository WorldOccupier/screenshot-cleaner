import CleanerMCP
import Foundation

// MCP over stdio: one JSON-RPC message per line in, one per line out. Logs would go to stderr; stdout is protocol only.
let server = MCPServer(tools: .live())
while let line = readLine(strippingNewline: true) {
    guard !line.isEmpty, let reply = server.handle(Data(line.utf8)) else { continue }
    FileHandle.standardOutput.write(reply + Data("\n".utf8))
}
