import SwiftUI

// Central look for build day. Reskinned later from Figma via MCP.
enum Theme {
    static let accent = Color(red: 1.0, green: 0.45, blue: 0.30)      // warm coral
    static let accentSoft = Color(red: 1.0, green: 0.45, blue: 0.30).opacity(0.15)
    static let card = Color(.secondarySystemBackground)
    static let background = Color(.systemBackground)

    // ID Card / Poster colorways, keyed by name stored in Firestore
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
