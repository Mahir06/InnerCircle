import Foundation
import FirebaseFirestore

// Firestore access for circles/{circleId}/games/{sessionId}
final class GameSessionRepository {
    private var db: Firestore { FirebaseManager.shared.db }
    private var configured: Bool { FirebaseManager.shared.isConfigured }

    private func games(_ circleId: String) -> CollectionReference {
        db.collection("circles").document(circleId).collection("games")
    }

    @discardableResult
    func createSession(_ session: GameSession, circleId: String) async throws -> String {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let ref = try games(circleId).addDocument(from: session)
        return ref.documentID
    }

    func listenSession(id: String, circleId: String, onChange: @escaping (GameSession?) -> Void) -> ListenerRegistration? {
        guard configured else {
            onChange(nil)
            return nil
        }
        return games(circleId).document(id).addSnapshotListener { snapshot, _ in
            onChange(try? snapshot?.data(as: GameSession.self))
        }
    }

    // Open tables: lobbies and running games, for the shelf and home.
    func listenActiveSessions(circleId: String, onChange: @escaping ([GameSession]) -> Void) -> ListenerRegistration? {
        guard configured else {
            onChange([])
            return nil
        }
        return games(circleId)
            .whereField("state", in: [GameState.lobby.rawValue, GameState.active.rawValue])
            .addSnapshotListener { snapshot, _ in
                let sessions = snapshot?.documents.compactMap { try? $0.data(as: GameSession.self) } ?? []
                onChange(sessions.sorted { $0.createdAt > $1.createdAt })
            }
    }

    func join(sessionId: String, userId: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await games(circleId).document(sessionId).updateData([
            "players": FieldValue.arrayUnion([userId]),
            "scores.\(userId)": 0,
        ])
    }

    func submit(sessionId: String, userId: String, value: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await games(circleId).document(sessionId).updateData([
            "submissions.\(userId)": value
        ])
    }

    func vote(sessionId: String, userId: String, target: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await games(circleId).document(sessionId).updateData([
            "votes.\(userId)": target
        ])
    }

    // Host-driven transitions: start, phase moves, round advances, finish.
    // The game rules compute the field changes; this just writes them.
    func update(sessionId: String, fields: [String: Any], circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await games(circleId).document(sessionId).updateData(fields)
    }
}
