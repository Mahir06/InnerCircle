import SwiftUI
import UIKit
import CoreText

// Design system v2: purple brand, Fraunces display type, Snapchat-adjacent
// chunky surfaces. Every screen pulls from here; reskins stay one-file.
enum Theme {
    // MARK: brand

    static let accent = Color(red: 0.48, green: 0.27, blue: 0.92)          // inner circle purple
    static let accentDeep = Color(red: 0.35, green: 0.16, blue: 0.75)
    static let accentSoft = Color(red: 0.48, green: 0.27, blue: 0.92).opacity(0.13)
    static let card = Color(.secondarySystemBackground)
    static let background = Color(.systemBackground)
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)           // postcard paper
    static let ink = Color(red: 0.16, green: 0.12, blue: 0.22)

    // MARK: type — Fraunces for display, system for utility text

    // Registers the bundled variable fonts once at launch (no Info.plist keys needed).
    static func registerFonts() {
        for name in ["Fraunces-Variable", "Fraunces-Italic-Variable"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        applyNavigationAppearance()
    }

    // Fraunces navigation titles everywhere, one appearance proxy.
    private static func applyNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        if let large = uiFont(size: 32, weight: .black) {
            appearance.largeTitleTextAttributes = [.font: large]
        }
        if let inline = uiFont(size: 18, weight: .bold) {
            appearance.titleTextAttributes = [.font: inline]
        }
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    private static func uiFont(size: CGFloat, weight: UIFont.Weight) -> UIFont? {
        guard let base = UIFont(name: "Fraunces", size: size) else { return nil }
        let descriptor = base.fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: size)
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.custom("Fraunces", size: size).weight(weight)
    }

    static func displayItalic(_ size: CGFloat) -> Font {
        Font.custom("Fraunces", size: size).italic()
    }

    // shorthand styles used across screens
    static var titleXL: Font { display(34, weight: .black) }
    static var title: Font { display(26, weight: .black) }
    static var heading: Font { display(19, weight: .bold) }
    static var cardTitle: Font { display(16, weight: .bold) }

    // MARK: colorways (ID cards, posters, decks)

    static let colorways: [String: Color] = [
        "sunset": Color(red: 1.0, green: 0.45, blue: 0.30),
        "grape": Color(red: 0.55, green: 0.35, blue: 0.95),
        "mint": Color(red: 0.20, green: 0.75, blue: 0.55),
        "sky": Color(red: 0.25, green: 0.60, blue: 0.95),
        "bubblegum": Color(red: 0.95, green: 0.45, blue: 0.70),
        "mango": Color(red: 1.0, green: 0.70, blue: 0.20),
    ]

    static func colorway(_ name: String) -> Color {
        colorways[name] ?? accent
    }
}

// MARK: - shared component styles

// The big friendly action button used everywhere.
struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color = Theme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.display(17, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(fill, in: RoundedRectangle(cornerRadius: 20))
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .shadow(color: fill.opacity(configuration.isPressed ? 0.15 : 0.35),
                    radius: configuration.isPressed ? 4 : 10, y: 4)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

extension View {
    // Snapchat-style chunky surface: fat radius, soft shadow.
    func chunkyCard(_ background: Color = Theme.card) -> some View {
        self
            .background(background, in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}
