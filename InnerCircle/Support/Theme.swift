import SwiftUI
import UIKit
import CoreText

// Design system v3 — Duolingo-grade finesse, Inner Circle purple.
// Language: rounded-heavy type, white cards with crisp 2px borders and a
// hard bottom edge, 3D pressable buttons, ALL-CAPS gray section labels,
// one saturated hue per concept, illustration-first empty states.
// Fraunces survives only on postcard paper (the analog counterpoint).
enum Theme {
    // MARK: brand

    static let accent = Color(red: 0.48, green: 0.27, blue: 0.92)          // inner circle purple
    static let accentDeep = Color(red: 0.36, green: 0.18, blue: 0.74)      // pressed edge
    static let accentSoft = Color(red: 0.48, green: 0.27, blue: 0.92).opacity(0.12)

    static let card = Color(.secondarySystemBackground)                   // flat gray surfaces (bubbles, fields)
    static let cardFace = Color(.systemBackground)                         // duo cards are white
    static let cardBorder = Color(.systemGray5)
    static let background = Color(.systemBackground)
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)           // postcard paper
    static let ink = Color(red: 0.16, green: 0.12, blue: 0.22)
    static let textSecondary = Color(.systemGray)                          // duolingo "hare" gray

    // MARK: type — SF Rounded heavy for UI, Fraunces for paper moments

    static func registerFonts() {
        for name in ["Fraunces-Variable", "Fraunces-Italic-Variable"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        applyNavigationAppearance()
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // the analog voice: postcards, envelopes, quotes only
    static func displayItalic(_ size: CGFloat) -> Font {
        Font.custom("Fraunces", size: size).italic()
    }

    static var titleXL: Font { display(32) }
    static var title: Font { display(25) }
    static var heading: Font { display(18, weight: .bold) }
    static var cardTitle: Font { display(16, weight: .bold) }

    // MARK: colorways (duolingo-flat, one hue per concept)

    static let colorways: [String: Color] = [
        "sunset": Color(red: 1.00, green: 0.44, blue: 0.26),
        "grape": Color(red: 0.58, green: 0.36, blue: 0.98),
        "mint": Color(red: 0.19, green: 0.80, blue: 0.51),
        "sky": Color(red: 0.11, green: 0.69, blue: 0.96),
        "bubblegum": Color(red: 0.98, green: 0.42, blue: 0.72),
        "mango": Color(red: 1.00, green: 0.72, blue: 0.10),
    ]

    static func colorway(_ name: String) -> Color {
        colorways[name] ?? accent
    }

    // MARK: navigation appearance (rounded heavy everywhere)

    private static func applyNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.largeTitleTextAttributes = [.font: roundedUIFont(size: 30, weight: .heavy)]
        appearance.titleTextAttributes = [.font: roundedUIFont(size: 17, weight: .bold)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    private static func roundedUIFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}

// MARK: - components

// Duolingo-style 3D button: uppercase heavy label, hard darker bottom
// edge, presses DOWN into the edge.
struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color = Theme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .textCase(.uppercase)
            .kerning(0.8)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)          // the edge
                        .fill(fill)
                        .brightness(-0.16)
                        .offset(y: 4)
                    RoundedRectangle(cornerRadius: 16)          // the face
                        .fill(fill)
                        .offset(y: configuration.isPressed ? 3 : 0)
                }
            )
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// ALL-CAPS gray section label (OVERVIEW / ACHIEVEMENTS energy)
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .textCase(.uppercase)
            .kerning(1.1)
            .foregroundStyle(Theme.textSecondary)
    }
}

extension View {
    // Duolingo card: face color, crisp 2px border, hard bottom edge.
    // Pass a tint for colored info cards; default is a white card.
    func chunkyCard(_ background: Color = Theme.cardFace) -> some View {
        self.background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Theme.cardBorder)
                    .offset(y: 2.5)
                RoundedRectangle(cornerRadius: 18)
                    .fill(background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Theme.cardBorder, lineWidth: 2)
                    )
            }
        )
    }
}
