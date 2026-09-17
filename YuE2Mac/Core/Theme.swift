//
//  Theme.swift — KokoroMac-derived ambient theming: material cards, adaptive
//  text, animated glow background. Music-flavoured.
//

import SwiftUI

/// App theme. `isTrueDark` drives whether cards use a solid fill (dark) or
/// translucent material (light).
enum AppTheme: String, CaseIterable, Identifiable {
    case studio = "Studio"        // default: dark, warm
    case stage = "Stage"          // deep electric blue
    case vinyl = "Vinyl"          // warm amber / tan

    var id: String { rawValue }
    var displayName: String { rawValue }

    var isTrueDark: Bool { true }   // every theme here is a dark, studio look

    var accentColor: Color {
        switch self {
        case .studio: return Color(red: 0.94, green: 0.55, blue: 0.30)      // warm amber
        case .stage:  return Color(red: 0.30, green: 0.55, blue: 0.97)      // electric blue
        case .vinyl:  return Color(red: 0.30, green: 0.72, blue: 0.54)      // jade green
        }
    }

    var palette: ThemePalette? {
        switch self {
        case .studio:
            return ThemePalette(
                centerDark: [Color.black.opacity(0.25), Color.black.opacity(0.65)],
                primaryGlow: [Color(red: 0.94, green: 0.55, blue: 0.30).opacity(0.22),
                              Color(red: 0.5, green: 0.2, blue: 0.5).opacity(0.10), .clear],
                diffuseWash: [.clear, Color(red: 0.4, green: 0.2, blue: 0.45).opacity(0.10)],
                animationSpeed: 175
            )
        case .stage:
            return ThemePalette(
                centerDark: [Color.black.opacity(0.2), Color.black.opacity(0.7)],
                primaryGlow: [Color(red: 0.3, green: 0.55, blue: 0.97).opacity(0.26),
                              Color(red: 0.1, green: 0.3, blue: 0.7).opacity(0.10), .clear],
                diffuseWash: [.clear, Color(red: 0.1, green: 0.25, blue: 0.6).opacity(0.13)],
                animationSpeed: 175
            )
        case .vinyl:
            return ThemePalette(
                centerDark: [Color.black.opacity(0.2), Color.black.opacity(0.6)],
                primaryGlow: [Color(red: 0.30, green: 0.72, blue: 0.54).opacity(0.24),
                              Color(red: 0.15, green: 0.45, blue: 0.35).opacity(0.10), .clear],
                diffuseWash: [.clear, Color(red: 0.15, green: 0.45, blue: 0.35).opacity(0.12)],
                animationSpeed: 175
            )
        }
    }
}

struct ThemePalette {
    let centerDark: [Color]
    let primaryGlow: [Color]
    let diffuseWash: [Color]
    let animationSpeed: Double
}

// MARK: - Card container (rounded material card with a 1px border)

struct CardContainer<Content: View>: View {
    let theme: AppTheme
    var fillColor: Color? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(fillColor ?? Color(red: 0.09, green: 0.09, blue: 0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.isTrueDark ? Color.white.opacity(0.08) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .overlay(content())
    }
}

// MARK: - Ambient animated background

struct AmbientThemeBackground: View {
    let theme: AppTheme
    @State private var p1 = false
    @State private var p2 = false
    @State private var running = false

    var body: some View {
        ZStack {
            // Solid dark base, then soft color glows on top for each theme.
            Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
            if let palette = theme.palette {
                RadialGradient(gradient: Gradient(colors: palette.centerDark), center: .center, startRadius: 0, endRadius: 260)
                RadialGradient(gradient: Gradient(colors: palette.primaryGlow),
                               center: p1 ? UnitPoint(x: 0.18, y: 0.22) : UnitPoint(x: 0.82, y: 0.78),
                               startRadius: 0, endRadius: 310).blendMode(.screen)
                RadialGradient(gradient: Gradient(colors: palette.primaryGlow.reversed()),
                               center: p2 ? UnitPoint(x: 0.78, y: 0.20) : UnitPoint(x: 0.22, y: 0.80),
                               startRadius: 0, endRadius: 280).opacity(0.55).blendMode(.screen)
                LinearGradient(gradient: Gradient(colors: palette.diffuseWash),
                               startPoint: p1 ? .topTrailing : .bottomLeading, endPoint: .center).blendMode(.softLight)
            }
        }
        .onAppear {
            guard !running, let speed = theme.palette?.animationSpeed else { return }
            running = true
            withAnimation(.easeInOut(duration: speed).repeatForever(autoreverses: true)) { p1 = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + speed * 0.5) {
                guard running else { return }
                withAnimation(.easeInOut(duration: speed * 1.3).repeatForever(autoreverses: true)) { p2 = true }
            }
        }
        .onDisappear { running = false; p1 = false; p2 = false }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}