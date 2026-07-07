import SwiftUI

// The deck experience: oversized type, one idea per card, deal by swipe.
// Skip is always one tap away.
struct GameDeckView: View {
    let game: OfflineGame

    @State private var selectedDeckId: String?
    @State private var cards: [String] = []
    @State private var index = 0

    private var selectedDeck: GameDeck? {
        game.decks.first { $0.id == selectedDeckId }
    }

    var body: some View {
        VStack(spacing: 16) {
            if game.decks.count > 1 {
                deckPicker
            }
            if cards.isEmpty {
                Spacer()
                Text(game.emoji).font(.system(size: 64))
                Text(game.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                if game.decks.count == 1 {
                    dealButton
                }
                Spacer()
            } else {
                cardStage
                controls
            }
        }
        .padding(.vertical, 16)
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if game.decks.count == 1 {
                selectedDeckId = game.decks.first?.id
            }
        }
    }

    private var deckPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(game.decks) { deck in
                    Button {
                        selectedDeckId = deck.id
                        deal(deck)
                    } label: {
                        Text(deck.name)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(deck.id == selectedDeckId ? Theme.colorway(game.colorway) : Theme.card,
                                        in: Capsule())
                            .foregroundStyle(deck.id == selectedDeckId ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var dealButton: some View {
        Button {
            if let deck = game.decks.first {
                selectedDeckId = deck.id
                deal(deck)
            }
        } label: {
            Text("deal the cards 🎴")
                .font(.headline)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Theme.colorway(game.colorway), in: Capsule())
                .foregroundStyle(.white)
        }
    }

    private var cardStage: some View {
        TabView(selection: $index) {
            ForEach(cards.indices, id: \.self) { i in
                VStack(spacing: 14) {
                    Text(game.emoji).font(.system(size: 34))
                    Text(cards[i])
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Theme.colorway(game.colorway).gradient,
                    in: RoundedRectangle(cornerRadius: 28)
                )
                .padding(.horizontal, 24)
                .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.spring(duration: 0.35), value: index)
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Text("card \(index + 1) of \(cards.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 14) {
                Button {
                    if let deck = selectedDeck { deal(deck) }
                } label: {
                    Label("shuffle", systemImage: "shuffle")
                        .font(.caption.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.card, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation { index = min(index + 1, cards.count - 1) }
                } label: {
                    Label(index >= cards.count - 1 ? "deck's done" : "skip / next",
                          systemImage: "arrow.right")
                        .font(.caption.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.colorway(game.colorway).opacity(0.2), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(index >= cards.count - 1)
            }
        }
    }

    private func deal(_ deck: GameDeck) {
        cards = deck.cards.shuffled()
        index = 0
    }
}
