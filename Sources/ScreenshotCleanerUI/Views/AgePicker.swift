import AppKit
import CleanerCore
import SwiftUI

/// "Older than  [All]  [7 days]" — hold and drag the day field up or down to change it.
struct AgePicker: View {
    @Binding var days: Int

    var body: some View {
        HStack(spacing: 0) {
            Text(AgeOption.caption(forDays: days))
                .contentTransition(.interpolate)
                .frame(width: 80, alignment: .leading)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .animation(.easeOut(duration: 0.18), value: days == 0)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                AllButton(days: $days)
                DayField(days: $days)
            }
        }
        .frame(height: 30)
    }
}

private struct AllButton: View {
    @Binding var days: Int
    @State private var hovering = false

    private var selected: Bool { days == 0 }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                days = 0
            }
        } label: {
            Text("All")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(selected ? AnyShapeStyle(.primary.opacity(0.82)) : AnyShapeStyle(.secondary))
                .frame(width: 44, height: 30)
                .background {
                    Capsule()
                        .fill(selected ? Color.primary.opacity(0.14) : Color.primary.opacity(hovering ? 0.06 : 0))
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.18), value: selected)
        .accessibilityLabel("All ages")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .help("Include screenshots of any age")
    }
}

private struct DayField: View {
    @Binding var days: Int

    @FocusState private var focused: Bool
    @State private var hovering = false
    @State private var lastDays = AgeOption.default
    @State private var dragOrigin: Double?
    @State private var dragging = false

    private var isAll: Bool { days == 0 }
    private var shownDays: Int { isAll ? lastDays : AgeOption.clamp(days) }
    private var showsGrip: Bool { hovering || focused || dragging }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack(spacing: 5) {
                // Fixed slot so the grip stays put as the value's width changes.
                fieldLabel
                    .frame(width: 42)

                grip
            }
            .offset(x: -1)

            Spacer(minLength: 0)
        }
        .frame(width: 76, height: 30)
        .background { fieldBackground }
        .overlay { border }
        .overlay { focusRing }
        .contentShape(Capsule())
        .brightness(hovering && !dragging ? 0.025 : 0)
        .animation(.easeOut(duration: 0.15), value: showsGrip)
        .animation(.easeOut(duration: 0.18), value: isAll)
        .animation(.snappy(duration: 0.18), value: shownDays)
        .focusable(true)
        .focused($focused)
        .focusEffectDisabled()
        .gesture(dragGesture)
        .onHover { inside in
            hovering = inside
            updateCursor()
        }
        .onKeyPress(.upArrow) {
            adjust(by: 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            adjust(by: -1)
            return .handled
        }
        .onAppear { syncLastDays() }
        .onChange(of: days) { _, _ in syncLastDays() }
        .onDisappear {
            dragOrigin = nil
            dragging = false
            NSCursor.arrow.set()
        }
        .accessibilityElement()
        .accessibilityLabel("Age")
        .accessibilityValue(isAll ? "Any age" : "\(shownDays) day\(shownDays == 1 ? "" : "s")")
        .accessibilityHint("Drag up or down to change")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: adjust(by: 1)
            case .decrement: adjust(by: -1)
            @unknown default: break
            }
        }
        .help("Drag up or down to choose 1–30 days")
    }

    @ViewBuilder
    private var fieldLabel: some View {
        if isAll {
            Text("Any")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(shownDays)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(shownDays)))

                Text(shownDays == 1 ? "day" : "days")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary.opacity(0.82))
            .lineLimit(1)
            .fixedSize()
            .transition(.opacity)
        }
    }

    private var grip: some View {
        VStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 2) {
                    Circle().frame(width: 2, height: 2)
                    Circle().frame(width: 2, height: 2)
                }
            }
        }
        .foregroundStyle(.secondary)
        .frame(width: 6, height: 10)
        .opacity(dragging ? 0.9 : (showsGrip ? 0.55 : 0.3))
        .animation(.easeOut(duration: 0.12), value: dragging)
        .animation(.easeOut(duration: 0.15), value: showsGrip)
    }

    private var fieldBackground: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: isAll
                        ? [Color.primary.opacity(0.075), Color.primary.opacity(0.045)]
                        : [Color.primary.opacity(0.18), Color.primary.opacity(0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
    }

    private var border: some View {
        Capsule()
            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
    }

    @ViewBuilder
    private var focusRing: some View {
        if focused {
            Capsule()
                .strokeBorder(Color.primary.opacity(0.3), lineWidth: 1)
                .padding(0.5)
                .transition(.opacity)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                focused = true

                if dragOrigin == nil {
                    guard abs(value.translation.height) >= 4 else { return }
                    dragOrigin = Double(isAll ? lastDays : AgeOption.clamp(days))
                    dragging = true
                    updateCursor()
                }

                guard let origin = dragOrigin else { return }

                let position = origin - Double(value.translation.height) / 10
                let next = AgeOption.clamp(Int(position.rounded()))
                if next != days {
                    days = next
                }
            }
            .onEnded { _ in
                if dragOrigin == nil, isAll {
                    withAnimation(.snappy(duration: 0.18)) {
                        days = lastDays
                    }
                }

                dragOrigin = nil
                dragging = false
                updateCursor()
            }
    }

    private func adjust(by delta: Int) {
        let current = isAll ? lastDays : AgeOption.clamp(days)
        let next = AgeOption.clamp(current + delta)

        withAnimation(.snappy(duration: 0.18)) {
            days = next
        }
    }

    private func syncLastDays() {
        if days > 0 {
            lastDays = AgeOption.clamp(days)
        }
    }

    private func updateCursor() {
        if dragging {
            NSCursor.closedHand.set()
        } else if hovering {
            NSCursor.openHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }
}
