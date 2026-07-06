import Foundation
import FirebaseFirestore

// Firestore access for circles/{circleId}
final class CircleRepository {
    private var db: Firestore { FirebaseManager.shared.db }
    private var configured: Bool { FirebaseManager.shared.isConfigured }

    enum CircleError: LocalizedError {
        case ticketNotFound
        case circleFull
        case alreadyInCircle

        var errorDescription: String? {
            switch self {
            case .ticketNotFound: return "no clubhouse answers to that ticket. typo check?"
            case .circleFull: return "this circle is packed. 10 is the magic number"
            case .alreadyInCircle: return "you already have a circle. one circle per human"
            }
        }
    }

    // Creates the circle and stamps circleId on the creator, atomically.
    func createCircle(name: String, coverEmoji: String, creatorId: String) async throws -> FriendCircle {
        guard configured else { throw FirebaseManager.notConfiguredError }

        var circle = FriendCircle.new(name: name, coverEmoji: coverEmoji, creatorId: creatorId)
        // Group Tickets are random enough that a collision is rare; retry a few times anyway
        for _ in 0..<3 {
            let clash = try await db.collection("circles")
                .whereField("code", isEqualTo: circle.code)
                .limit(to: 1)
                .getDocuments()
            if clash.isEmpty { break }
            circle.code = FriendCircle.generateGroupTicket()
        }

        let circleRef = db.collection("circles").document()
        let userRef = db.collection("users").document(creatorId)
        let batch = db.batch()
        try batch.setData(from: circle, forDocument: circleRef)
        batch.updateData(["circleId": circleRef.documentID], forDocument: userRef)
        try await batch.commit()

        circle.id = circleRef.documentID
        return circle
    }

    // Looks up the Group Ticket and joins, atomically.
    func joinCircle(code: String, userId: String) async throws -> String {
        guard configured else { throw FirebaseManager.notConfiguredError }

        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let match = try await db.collection("circles")
            .whereField("code", isEqualTo: normalized)
            .limit(to: 1)
            .getDocuments()
        guard let doc = match.documents.first else { throw CircleError.ticketNotFound }

        let memberIds = doc.data()["memberIds"] as? [String] ?? []
        if memberIds.contains(userId) { return doc.documentID }
        guard memberIds.count < FriendCircle.maxMembers else { throw CircleError.circleFull }

        let userRef = db.collection("users").document(userId)
        let batch = db.batch()
        batch.updateData(["memberIds": FieldValue.arrayUnion([userId])], forDocument: doc.reference)
        batch.updateData(["circleId": doc.documentID], forDocument: userRef)
        try await batch.commit()
        return doc.documentID
    }

    func listenCircle(id: String, onChange: @escaping (FriendCircle?) -> Void) -> ListenerRegistration? {
        guard configured else {
            onChange(nil)
            return nil
        }
        return db.collection("circles").document(id).addSnapshotListener { snapshot, _ in
            onChange(try? snapshot?.data(as: FriendCircle.self))
        }
    }

    func listenMembers(circleId: String, onChange: @escaping ([AppUser]) -> Void) -> ListenerRegistration? {
        guard configured else {
            onChange([])
            return nil
        }
        return db.collection("users")
            .whereField("circleId", isEqualTo: circleId)
            .addSnapshotListener { snapshot, _ in
                let members = snapshot?.documents.compactMap { try? $0.data(as: AppUser.self) } ?? []
                onChange(members.sorted { $0.createdAt < $1.createdAt })
            }
    }

    func updateBucketList(_ items: [BucketListItem], circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let payload = items.map { item -> [String: Any] in
            var dict: [String: Any] = ["id": item.id, "label": item.label, "done": item.done]
            if let doneHangoutId = item.doneHangoutId { dict["doneHangoutId"] = doneHangoutId }
            return dict
        }
        try await db.collection("circles").document(circleId).updateData(["bucketList": payload])
    }

    func updateCircleProfile(name: String, coverEmoji: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await db.collection("circles").document(circleId).updateData([
            "name": name,
            "coverEmoji": coverEmoji,
        ])
    }
}
