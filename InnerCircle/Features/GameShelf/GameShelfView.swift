import SwiftUI

// The Game Shelf: 10 offline party decks live now, 10 online games
// arriving with the Week 1 build.
struct GameShelfView: View {
    private let games = GameContentRepository().offlineGames()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("phone = card dealer. pick a deck, pass it around")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(games) { game in
                        NavigationLink(value: game.id) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(game.emoji).font(.system(size: 34))
                                Text(game.title)
                                    .font(.subheadline.bold())
                                    .multilineTextAlignment(.leading)
                                Text(game.tagline)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                            .padding(12)
                            .background(Theme.colorway(game.colorway).opacity(0.14),
                                        in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("online games · coming this week")
                    .font(.headline)
                    .padding(.top, 8)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(OnlineGameTeaser.catalog) { game in
                        HStack(spacing: 8) {
                            Text(game.emoji)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(game.title).font(.caption.bold())
                                Text(game.tagline)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(10)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                        .opacity(0.7)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Game Shelf")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: String.self) { gameId in
            if let game = games.first(where: { $0.id == gameId }) {
                GameDeckView(game: game)
            }
        }
    }
}
