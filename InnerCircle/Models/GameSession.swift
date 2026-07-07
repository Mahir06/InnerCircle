import Foundation
import FirebaseFirestore

// One shared schema for every online game: turn-based over Firestore
// listeners, no servers. The host's device advances rounds; everyone
// else just submits and votes. `board` is a flat string map that holds
// per-game state (roles, squads, tallies) and is reserved room for
// board games (Isle of Settlers) later.
nonisolated struct GameSession: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var gameId: String
    var hostId: String
    var players: [String]
    var state: GameState
    var round: Int
    var totalRounds: Int
    var phase: String                     // per-game label: collect | write | vote | squad | mission
    var prompts: [String]
    var submissions: [String: String]     // uid -> value for the current round
    var votes: [String: String]           // uid -> target for the current round
    var scores: [String: Int]
    var board: [String: String]
    var createdAt: Date

    var currentPrompt: String? {
        prompts.indices.contains(round) ? prompts[round] : nil
    }

    func isHost(_ uid: String) -> Bool { hostId == uid }
}

nonisolated enum GameState: String, Codable {
    case lobby, active, done
}

// The catalog entry for games that are actually playable online.
nonisolated struct OnlineGame: Identifiable, Equatable {
    let id: String
    let title: String
    let emoji: String
    let tagline: String
    let minPlayers: Int
    let rounds: Int

    static let playable: [OnlineGame] = [
        OnlineGame(id: "mostLikelyTo", title: "Most Likely To", emoji: "👉",
                   tagline: "vote a friend, reveal the pie of shame", minPlayers: 2, rounds: 5),
        OnlineGame(id: "hotTakes", title: "Hot Takes", emoji: "🌶️",
                   tagline: "lock a side. the minority defends themselves", minPlayers: 2, rounds: 5),
        OnlineGame(id: "fibber", title: "Fibber", emoji: "🤥",
                   tagline: "fake answers, one truth, fool your friends", minPlayers: 3, rounds: 5),
        OnlineGame(id: "theSnake", title: "The Snake", emoji: "🐍",
                   tagline: "two snakes among us. missions, sabotage, betrayal", minPlayers: 4, rounds: 5),
    ]

    static func byId(_ id: String) -> OnlineGame? {
        playable.first { $0.id == id }
    }
}
