import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class GameShelfViewModel: ObservableObject {
    @Published var activeSessions: [GameSession] = []
    @Published var errorMessage: String?

    private let repo = GameSessionRepository()
    private var listener: ListenerRegistration?
    private(set) var circleId = ""
    private(set) var userId = ""

    func start(circleId: String, userId: String) {
        guard self.circleId != circleId || listener == nil else { return }
        stop()
        self.circleId = circleId
        self.userId = userId
        if DemoContent.isActive { return }
        listener = repo.listenActiveSessions(circleId: circleId) { [weak self] sessions in
            Task { @MainActor in
                self?.activeSessions = sessions
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    // Opens a lobby, drops the invite in chat, hands back the session id.
    func openTable(_ game: OnlineGame) async -> String? {
        do {
            return try await GameSessionViewModel.openTable(game: game, hostId: userId, circleId: circleId)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
