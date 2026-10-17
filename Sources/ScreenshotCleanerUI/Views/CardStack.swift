import CleanerCore
import SwiftUI

/// A fanned deck you can flip through: the current screenshot sits in front, its neighbours fan out behind.
/// Trackpad swipes and drags move the deck continuously under your fingers, then it settles with a soft spring.
/// The motion maths lives in `Deck`/`CardPose`; scroll handling in `ScrollInterpreter`.
struct CardStack: View {
    let items: [Screenshot] // newest first
    @State private var deck = Deck()
    @State private var scroll = ScrollInterpreter()
    @State private var hovering = false
    @State private var scrollMonitor: ScrollWheelMonitor?

    private static let settle = Animation.spring(response: 0.85, dampingFraction: 0.86)

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if items.isEmpty {
                    emptyState.transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                ForEach(deck.visible.filter { $0.index < items.count }, id: \.index) { index, offset in
                    let pose = CardPose(position: deck.position(ofOffset: offset))
                    ScreenshotCard(url: items[index].url)
                        .brightness(pose.brightness)
                        .scaleEffect(pose.scale)
                        .rotationEffect(.degrees(pose.rotation))
                        .offset(x: pose.x, y: pose.y)
                        .opacity(pose.opacity)
                        .zIndex(pose.zIndex)
                        .allowsHitTesting(abs(offset) == 1)
                        .onTapGesture { animate { deck.settle(to: index) } }
                        .transition(.opacity)
                        .id(items[index].id)
                }
            }
            .frame(height: 78)
            // Counter gets its own row so the fanned cards never overlap it.
            Text(deck.counterText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.tertiary)
                .contentTransition(.numericText(value: Double(deck.index)))
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { deck.follow(travel: -$0.translation.width) }
                .onEnded { value in animate { deck.release(predictedTravel: -value.predictedEndTranslation.width) } }
        )
        .onAppear {
            deck.update(count: items.count)
            scrollMonitor = ScrollWheelMonitor(handler: handleScroll)
        }
        .onDisappear { scrollMonitor = nil }
        .onChange(of: items.map(\.id)) { deck.update(count: items.count) }
    }

    private var emptyState: some View {
        ZStack {
            Circle().fill(.quaternary.opacity(0.6)).frame(width: 64, height: 64)
            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    /// Consumes scroll events while the pointer is over the deck (or a trackpad gesture is in progress).
    private func handleScroll(_ input: ScrollInput) -> Bool {
        guard hovering || scroll.isTracking else { return false }
        switch scroll.handle(input) {
        case .ignore: break
        case .follow(let travel): deck.follow(travel: travel)
        case .release: animate { deck.release() }
        case .step(let direction): animate { deck.settle(to: deck.index + direction) }
        }
        return true
    }

    private func animate(_ change: () -> Void) {
        withAnimation(Self.settle, change)
    }
}
