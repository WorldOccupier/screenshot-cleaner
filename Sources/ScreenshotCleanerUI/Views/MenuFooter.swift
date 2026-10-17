import AppKit
import SwiftUI

/// Auto-clean switch and quit.
struct MenuFooter: View {
    @Binding var autoClean: Bool

    var body: some View {
        HStack {
            Toggle(isOn: $autoClean) {
                Text("Auto-clean").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
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
