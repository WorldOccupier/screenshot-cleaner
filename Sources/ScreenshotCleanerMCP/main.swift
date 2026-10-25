import CleanerMCP
import Foundation

// MCP over stdio: one JSON-RPC message per line in, one per line out.
// stdout is protocol only; diagnostics go to the unified log (subsystem com.vatsa.ScreenshotCleaner).
let server = MCPServer(tools: .live())
while let line = readLine(strippingNewline: true) {
    guard !line.isEmpty, let reply = server.handle(Data(line.utf8)) else { continue }
    FileHandle.standardOutput.write(reply + Data("\n".utf8))
}
