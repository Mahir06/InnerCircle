import SwiftUI

// The Game Shelf: online multiplayer tables + 10 offline party decks.
struct GameShelfView: View {
    private let games = GameContentRepository().offlineGames()
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = GameShelfViewModel()
    @State private var openSession: SessionRef?

    struct SessionRef: Identifiable {
        let id: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                liveTables
                onlinePlayable

                Text("offline decks · phone = card dealer")
                    .font(.headline)
                    .padding(.top, 4)

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

                Text("in the workshop")
                    .font(.headline)
                    .padding(.top, 8)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(lockedTeasers) { game in
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
        .sheet(item: $openSession) { ref in
            NavigationStack {
                GameSessionView(sessionId: ref.id)
            }
        }
        .onAppear {
            if let circleId = appState.circle?.id, let uid = appState.authUid {
                vm.start(circleId: circleId, userId: uid)
            }
        }
    }

    // Isle of Settlers headlines the workshop: the engine's board field is
    // ready for it, the full build is the next games sprint.
    private var lockedTeasers: [OnlineGameTeaser] {
        let playableIds = Set(OnlineGame.playable.map(\.id))
        var teasers = OnlineGameTeaser.catalog.filter { !playableIds.contains($0.id) }
        teasers.insert(OnlineGameTeaser(
            id: "isleOfSettlers",
            title: "Isle of Settlers",
            emoji: "🏝️",
            tagline: "dice, resources, roads, ruined friendships"
        ), at: 0)
        return teasers
    }

    // MARK: live tables

    @ViewBuilder
    private var liveTables: some View {
        if !vm.activeSessions.isEmpty {
            Text("live tables")
                .font(.headline)
            ForEach(vm.activeSessions) { session in
                let game = OnlineGame.byId(session.gameId)
                Button {
                    if let id = session.id { openSession = SessionRef(id: id) }
                } label: {
                    HStack(spacing: 12) {
                        Text(game?.emoji ?? "🎮").font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(game?.title ?? session.gameId).font(.subheadline.bold())
                            Text(session.state == .lobby
                                 ? "\(session.players.count) at the table, waiting for players"
                                 : "round \(session.round + 1) in progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(session.state == .lobby ? "JOIN" : "WATCH")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.accent, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: online games

    private var onlinePlayable: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("online · play right now")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(OnlineGame.playable) { game in
                    Button {
                        Task {
                            if let id = await vm.openTable(game) {
                                openSession = SessionRef(id: id)
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(game.emoji).font(.system(size: 30))
                                Spacer()
                                Text("\(game.minPlayers)+")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                            }
                            Text(game.title)
                                .font(.subheadline.bold())
                                .multilineTextAlignment(.leading)
                            Text(game.tagline)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                        .padding(12)
                        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
            if let error = vm.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }
}
