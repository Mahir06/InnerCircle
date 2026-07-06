import SwiftUI

// Placeholder until the auth block. Splash story screens, email auth,
// and the create/join circle fork land here.
struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("⭕️").font(.system(size: 64))
            Text("Inner Circle").font(.largeTitle.bold())
            Text("your digital headquarters for friendship")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("auth coming in the next block")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 24)
        }
    }
}
