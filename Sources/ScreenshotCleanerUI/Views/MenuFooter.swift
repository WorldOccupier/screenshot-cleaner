import AppKit
import SwiftUI

/// Auto-clean and recordings switches, and quit.
struct MenuFooter: View {
    @Binding var autoClean: Bool
    @Binding var includeRecordings: Bool

    var body: some View {
        HStack {
            Toggle(isOn: $autoClean) {
                Text("Auto-clean").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            Toggle(isOn: $includeRecordings) {
                Text("Recordings").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            .help("Also clean screen recordings")
            Spacer()
            Button { NSApp.terminate(nil) } label: {
                Image(systemName: "power").font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
            .help("Quit")
        }
    }
}
