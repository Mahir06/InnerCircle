import SwiftUI

// Reusable stamp wall: shows every stamp with owner. Used on the Circle Page.
struct StampsGrid: View {
    let stamps: [Stamp]
    @EnvironmentObject var appState: AppState

    var body: some View {
        if stamps.isEmpty {
            Text("no stamps yet. show up first, host something, write the postcard")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(stamps) { stamp in
                    VStack(spacing: 4) {
                        Text(stamp.kind.emoji).font(.system(size: 28))
                        Text(stamp.kind.title)
                            .font(.caption2.bold())
                            .multilineTextAlignment(.center)
                        Text(appState.memberName(stamp.userId))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
