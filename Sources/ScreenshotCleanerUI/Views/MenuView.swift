import CleanerCore
import SwiftUI

/// The popover: count and card stack, age picker, clean button, footer.
public struct MenuView: View {
    @Environment(Store.self) private var store

    public init() {}

    public var body: some View {
        @Bindable var store = store
        VStack(spacing: 20) {
            hero
            AgePicker(days: $store.ageDays)
            CleanButton()
            MenuFooter(autoClean: $store.autoClean)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 14)
        .frame(width: 300)
        .background(alignment: .topTrailing) {
            // Soft accent glow behind the stack.
            RadialGradient(colors: [Color.accentColor.opacity(0.25), .clear], center: .topTrailing, startRadius: 0, endRadius: 240)
                .frame(height: 220)
                .allowsHitTesting(false)
        }
        .onAppear { store.rescan() }
        .animation(.spring(response: 0.7, dampingFraction: 0.9), value: store.items)
    }

    private var hero: some View {
        let summary = store.summary
        return HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(store.items.count)")
                    .font(.system(size: 54, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(store.items.count)))
                    .foregroundStyle(store.items.isEmpty ? .tertiary : .primary)
                Text(summary.primary)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                // Always reserve the second line so the hero never changes height.
                Text(summary.secondary ?? " ")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .contentTransition(.opacity)
            Spacer(minLength: 8)
            CardStack(items: store.items.reversed())
                .frame(width: 136)
        }
    }
}
