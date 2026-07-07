import Foundation
import Combine
import FirebaseFirestore

// Drives one game session. Everyone submits/votes; the host's device is
// the referee that starts the game, moves phases, applies scores, and
// ends it. All rules are pure functions of the session doc.
@MainActor
final class GameSessionViewModel: ObservableObject {
    @Published var session: GameSession?
    @Published var errorMessage: String?

    private let repo = GameSessionRepository()
    private let chatRepo = ChatRepository()
    private let content = GameContentRepository()
    private var listener: ListenerRegistration?
    private(set) var circleId = ""
    private(set) var userId = ""
    private var sessionId = ""

    func start(sessionId: String, circleId: String, userId: String) {
        guard self.sessionId != sessionId || listener == nil else { return }
        stop()
        self.sessionId = sessionId
        self.circleId = circleId
        self.userId = userId
        listener = repo.listenSession(id: sessionId, circleId: circleId) { [weak self] session in
            Task { @MainActor in
                self?.session = session
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    // MARK: - lobby

    // Creates a lobby and drops an invite in chat. Returns the session id.
    static func openTable(game: OnlineGame, hostId: String, circleId: String) async throws -> String {
        let content = GameContentRepository()
        var prompts: [String]
        switch game.id {
        case "mostLikelyTo": prompts = content.onlineDeck("most_likely_to").shuffled()
        case "hotTakes": prompts = content.onlineDeck("hot_takes").shuffled()
        case "fibber": prompts = content.onlineDeck("fibber_prompts").shuffled()
        case "theSnake": prompts = content.snakeContent().missions.shuffled()
        default: prompts = []
        }
        prompts = Array(prompts.prefix(max(game.rounds, 5)))

        let session = GameSession(
            gameId: game.id,
            hostId: hostId,
            players: [hostId],
            state: .lobby,
            round: 0,
            totalRounds: game.rounds,
            phase: "lobby",
            prompts: prompts,
            submissions: [:],
            votes: [:],
            scores: [hostId: 0],
            board: [:],
            createdAt: Date()
        )
        let repo = GameSessionRepository()
        let id = try await repo.createSession(session, circleId: circleId)
        try await ChatRepository().sendGameInvite(
            sessionId: id,
            title: "\(game.emoji) \(game.title)",
            senderId: hostId,
            circleId: circleId
        )
        return id
    }

    func join() {
        run { try await self.repo.join(sessionId: self.sessionId, userId: self.userId, circleId: self.circleId) }
    }

    func startGame() {
        guard let session, session.isHost(userId) else { return }
        var fields: [String: Any] = [
            "state": GameState.active.rawValue,
            "round": 0,
            "submissions": [:] as [String: String],
            "votes": [:] as [String: String],
        ]
        switch session.gameId {
        case "fibber":
            fields["phase"] = "write"
        case "theSnake":
            fields["phase"] = "squad"
            var board: [String: String] = ["fails": "0", "wins": "0"]
            let snakeCount = session.players.count >= 6 ? 2 : 1
            for snake in session.players.shuffled().prefix(snakeCount) {
                board["role_\(snake)"] = "snake"
            }
            fields["board"] = board
        default:
            fields["phase"] = "collect"
        }
        run { try await self.repo.update(sessionId: self.sessionId, fields: fields, circleId: self.circleId) }
    }

    // MARK: - player actions

    func submit(_ value: String) {
        run { try await self.repo.submit(sessionId: self.sessionId, userId: self.userId, value: value, circleId: self.circleId) }
    }

    func vote(_ target: String) {
        run { try await self.repo.vote(sessionId: self.sessionId, userId: self.userId, target: target, circleId: self.circleId) }
    }

    // MARK: - derived state

    var mySubmission: String? { session?.submissions[userId] }
    var myVote: String? { session?.votes[userId] }
    var isHost: Bool { session?.isHost(userId) ?? false }
    var iAmIn: Bool { session?.players.contains(userId) ?? false }

    var myRole: String {
        guard let session else { return "loyal" }
        return session.board["role_\(userId)"] ?? "loyal"
    }

    // Fibber: whose truth is on trial this round.
    var fibberSubject: String? {
        guard let session, !session.players.isEmpty else { return nil }
        return session.players[session.round % session.players.count]
    }

    // Snake: who picks the squad this round.
    var snakeCaptain: String? {
        guard let session, !session.players.isEmpty else { return nil }
        return session.players[session.round % session.players.count]
    }

    var snakeSquad: [String] {
        (session?.board["squad"] ?? "").split(separator: ",").map(String.init)
    }

    // Everyone expected this phase has submitted/voted.
    var allInputsIn: Bool {
        guard let session else { return false }
        switch (session.gameId, session.phase) {
        case ("mostLikelyTo", _):
            return session.votes.count >= session.players.count
        case ("hotTakes", _):
            return session.submissions.count >= session.players.count
        case ("fibber", "write"):
            return session.submissions.count >= session.players.count
        case ("fibber", "vote"):
            return session.votes.count >= session.players.count - 1   // subject doesn't vote
        case ("theSnake", "squad"):
            return !snakeSquad.isEmpty
        case ("theSnake", "mission"):
            return snakeSquad.allSatisfy { session.submissions[$0] != nil }
        default:
            return false
        }
    }

    // MARK: - host transitions

    // Fibber: all fibs are in, open voting.
    func openFibberVoting() {
        guard isHost else { return }
        run {
            try await self.repo.update(sessionId: self.sessionId, fields: ["phase": "vote"], circleId: self.circleId)
        }
    }

    // Snake: captain locks the squad, mission begins.
    func lockSquad(_ squad: [String]) {
        run {
            try await self.repo.update(sessionId: self.sessionId, fields: [
                "board.squad": squad.joined(separator: ","),
                "phase": "mission",
            ], circleId: self.circleId)
        }
    }

    // Applies this round's scores and moves on (or ends the game).
    func nextRound() {
        guard let session, isHost else { return }
        var fields: [String: Any] = [
            "submissions": [:] as [String: String],
            "votes": [:] as [String: String],
        ]
        var newScores = session.scores

        switch session.gameId {
        case "mostLikelyTo":
            // +1 shame point per vote received
            for target in session.votes.values {
                newScores[target, default: 0] += 1
            }
        case "hotTakes":
            break   // no scores, just vibes and arguments
        case "fibber":
            // votes are for the OWNER of the chosen answer
            let subject = fibberSubject ?? ""
            for (voter, chosenOwner) in session.votes {
                if chosenOwner == subject {
                    newScores[voter, default: 0] += 1          // found the truth
                } else {
                    newScores[chosenOwner, default: 0] += 2    // fooled a friend
                }
            }
            fields["phase"] = "write"
        case "theSnake":
            let sabotaged = session.submissions.values.contains("sabotage")
            var fails = Int(session.board["fails"] ?? "0") ?? 0
            var wins = Int(session.board["wins"] ?? "0") ?? 0
            if sabotaged { fails += 1 } else { wins += 1 }
            fields["board.fails"] = String(fails)
            fields["board.wins"] = String(wins)
            fields["board.squad"] = ""
            fields["board.lastMission"] = sabotaged ? "fail" : "pass"
            fields["phase"] = "squad"
            if fails >= 3 || wins >= 3 {
                fields["state"] = GameState.done.rawValue
                fields["board.winner"] = fails >= 3 ? "snakes" : "loyals"
            }
        default:
            break
        }

        fields["scores"] = newScores
        let nextRound = session.round + 1
        if session.gameId != "theSnake" && nextRound >= session.totalRounds {
            fields["state"] = GameState.done.rawValue
        } else if fields["state"] == nil {
            fields["round"] = nextRound
        }

        let announceDone = (fields["state"] as? String) == GameState.done.rawValue
        let snakeWinner = fields["board.winner"] as? String
        let champion = newScores.max { $0.value < $1.value }?.key
        run {
            try await self.repo.update(sessionId: self.sessionId, fields: fields, circleId: self.circleId)
            if announceDone {
                let game = OnlineGame.byId(session.gameId)
                var line = "\(game?.emoji ?? "🎮") \(game?.title ?? "the game") is over."
                if let snakeWinner {
                    line += " the \(snakeWinner) take it 🐍"
                } else if let champion {
                    line += " crown goes to <\(champion)> 👑"
                }
                try await self.chatRepo.sendSystem(line, circleId: self.circleId)
            }
        }
    }

    private func run(_ work: @escaping () async throws -> Void) {
        Task {
            do {
                try await work()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
