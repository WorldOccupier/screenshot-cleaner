import SwiftUI

/// "Move to Trash". Stays in place (dimmed) when there's nothing to clean so the popover never resizes.
struct CleanButton: View {
    @Environment(Store.self) private var store
    @State private var hovering = false

    var body: some View {
        let enabled = !store.items.isEmpty
        Button {
            Task { await store.clean() }
        } label: {
            HStack(spacing: 7) {
                if store.isWorking {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "trash")
                }
                Text(store.isWorking ? "Cleaning…" : "Move to Trash")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.background)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(Capsule().fill(.primary.opacity(hovering ? 1 : 0.9)))
            .scaleEffect(hovering && enabled ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .disabled(store.isWorking || !enabled)
        .opacity(enabled ? 1 : 0.25)
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { hovering = h } }
        .keyboardShortcut(.return)
    }
}
