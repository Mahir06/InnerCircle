import SwiftUI

// Achievement wall, Duolingo-style: chunky ringed badge tiles with the
// owner underneath. Slots into the Circle Page and ID cards.
struct StampsGrid: View {
    let stamps: [Stamp]
    @EnvironmentObject var appState: AppState

    private func ringColor(_ kind: StampKind) -> Color {
        switch kind {
        case .firstOneIn: return Theme.colorway("sky")
        case .host: return Theme.colorway("mango")
        case .scribe: return Theme.colorway("bubblegum")
        }
    }

    var body: some View {
        if stamps.isEmpty {
            Text("no stamps yet. show up first, host something, write the postcard")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(stamps) { stamp in
                    VStack(spacing: 6) {
                        Text(stamp.kind.emoji)
                            .font(.system(size: 30))
                            .frame(width: 58, height: 58)
                            .background(ringColor(stamp.kind).opacity(0.15), in: SwiftUI.Circle())
                            .overlay(
                                SwiftUI.Circle()
                                    .strokeBorder(ringColor(stamp.kind), lineWidth: 3.5)
                            )
                        Text(stamp.kind.title)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .multilineTextAlignment(.center)
                        Text(appState.memberName(stamp.userId))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .chunkyCard()
                }
            }
        }
    }
}
