// Renders the app icon: a centred fan of screenshot cards, matching the popover's stack.
// Usage: swift Scripts/MakeIcon.swift <output.png>
import AppKit
import SwiftUI

private struct ScreenshotCard: View {
    /// Glass cards are bare frosted panels; only the front card shows content.
    var glass: Double? = nil

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 34, style: .continuous)
        if let glass {
            shape
                .fill(LinearGradient(colors: [.white.opacity(glass), .white.opacity(glass * 0.45)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(shape.strokeBorder(.white.opacity(min(glass * 1.6, 0.7)), lineWidth: 2))
                .frame(width: 380, height: 260)
        } else {
            solid
        }
    }

    private var solid: some View {
        let shape = RoundedRectangle(cornerRadius: 34, style: .continuous)
        return ZStack(alignment: .topLeading) {
            shape.fill(LinearGradient(colors: [.white, Color(white: 0.9)], startPoint: .top, endPoint: .bottom))
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in Circle().fill(Color(white: 0.78)).frame(width: 18, height: 18) }
                }
                Capsule().fill(Color(white: 0.8)).frame(width: 230, height: 18)
                Capsule().fill(Color(white: 0.86)).frame(width: 160, height: 18)
            }
            .padding(36)
        }
        .frame(width: 380, height: 260)
        .overlay(shape.strokeBorder(.white.opacity(0.9), lineWidth: 2))
    }
}

private struct Icon: View {
    var body: some View {
        let squircle = RoundedRectangle(cornerRadius: 185, style: .continuous)
        ZStack {
            // Background: emerald, lit from the top-left.
            squircle.fill(LinearGradient(
                colors: [Color(red: 0.24, green: 0.86, blue: 0.56), Color(red: 0.05, green: 0.50, blue: 0.34), Color(red: 0.02, green: 0.20, blue: 0.14)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            squircle.fill(RadialGradient(
                colors: [Color(red: 0.75, green: 1, blue: 0.85).opacity(0.45), .clear],
                center: UnitPoint(x: 0.25, y: 0.12), startRadius: 0, endRadius: 520
            ))

            // Centred fan, mirroring the popover's card stack: neighbours tilt out behind the front card.
            ZStack {
                ForEach([-1.0, 1.0], id: \.self) { side in
                    ScreenshotCard(glass: 0.32)
                        .compositingGroup()
                        .shadow(color: .black.opacity(0.2), radius: 24, y: 14)
                        .scaleEffect(0.94)
                        .rotationEffect(.degrees(side * 11))
                        .offset(x: side * 130, y: 34)
                }
                ScreenshotCard()
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.35), radius: 40, y: 26)
            }
            .scaleEffect(1.22)
            .offset(y: -6)
        }
        .frame(width: 824, height: 824)
        .clipShape(squircle)
        .overlay(squircle.strokeBorder(.white.opacity(0.14), lineWidth: 3))
        .shadow(color: .black.opacity(0.3), radius: 24, y: 12)
        .frame(width: 1024, height: 1024)
    }
}

@MainActor func render(to path: String) {
    let renderer = ImageRenderer(content: Icon())
    renderer.scale = 1
    guard let cg = renderer.cgImage,
          let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])
    else { fatalError("render failed") }
    try! png.write(to: URL(fileURLWithPath: path))
}

MainActor.assumeIsolated { render(to: CommandLine.arguments[1]) }
