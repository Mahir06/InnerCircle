import Foundation
import FirebaseFirestore

// Firestore access for circles/{circleId}/stamps
final class StampRepository {
    private var db: Firestore { FirebaseManager.shared.db }
    private var configured: Bool { FirebaseManager.shared.isConfigured }

    func listenStamps(circleId: String, onChange: @escaping ([Stamp]) -> Void) -> ListenerRegistration? {
        guard configured else {
            onChange([])
            return nil
        }
        return db.collection("circles").document(circleId).collection("stamps")
            .order(by: "awardedAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let stamps = snapshot?.documents.compactMap { try? $0.data(as: Stamp.self) } ?? []
                onChange(stamps)
            }
    }

    // One-shot: the badges earned at a specific hangout (for postcards).
    func fetchStamps(hangoutId: String, circleId: String) async throws -> [Stamp] {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let snapshot = try await db.collection("circles").document(circleId).collection("stamps")
            .whereField("hangoutId", isEqualTo: hangoutId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Stamp.self) }
    }

    // Deterministic doc ID makes awarding idempotent: the client and the
    // awardStamps Cloud Function can both fire without double stamps.
    func awardStamp(kind: StampKind, userId: String, hangoutId: String?, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let docId = "\(hangoutId ?? "general")_\(kind.rawValue)_\(userId)"
        let stamp = Stamp(userId: userId, kind: kind, hangoutId: hangoutId, awardedAt: Date())
        try db.collection("circles").document(circleId).collection("stamps")
            .document(docId).setData(from: stamp)
    }
}
