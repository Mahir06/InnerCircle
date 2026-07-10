import SwiftUI
import UIKit

// Illustration slots, Duolingo-style: characters carry the emotion of
// every empty state and hero moment. Until real art exists, each slot
// renders a friendly placeholder. Drop a PNG named "illo-<slot>" into
// Assets.xcassets and it appears automatically — no code changes.
// The full slot list + art direction brief: docs/illustration-brief.md
struct Illustration: View {
    let slot: String
    var size: CGFloat = 140

    var body: some View {
        if UIImage(named: "illo-\(slot)") != nil {
            Image("illo-\(slot)")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: size, maxHeight: size)
        } else {
            // placeholder: dashed frame + slot name, so missing art is
            // visible and nameable during design reviews
            VStack(spacing: 6) {
                Text(Self.placeholderEmoji[slot] ?? "🎨")
                    .font(.system(size: size * 0.38))
                Text(slot)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.accentSoft.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Theme.accent.opacity(0.35),
                                          style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    )
            )
        }
    }

    // stand-in emoji per slot so placeholders still communicate
    static let placeholderEmoji: [String: String] = [
        "onboarding-circle": "⭕️",
        "onboarding-plans": "📅",
        "onboarding-postcard": "💌",
        "mascot-hello": "👋",
        "mascot-celebrate": "🎉",
        "mascot-search": "🔭",
        "mascot-sad": "🥺",
        "empty-chat": "🫥",
        "empty-hangouts": "🗓️",
        "empty-mailbox": "📭",
        "empty-shelf": "🎴",
        "locked-capsule": "🔒",
        "discover-hero": "🎟️",
        "games-hero": "🎮",
    ]
}
