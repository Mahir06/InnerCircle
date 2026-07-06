import Foundation
import FirebaseFirestore

// Firestore access for circles/{circleId}/postcards
final class PostcardRepository {
    // Contributors get this long before the envelope seals.
    static let sealWindow: TimeInterval = 2 * 86400

    private var db: Firestore { FirebaseManager.shared.db }
    private var configured: Bool { FirebaseManager.shared.isConfigured }

    private func postcards(_ circleId: String) -> CollectionReference {
        db.collection("circles").document(circleId).collection("postcards")
    }

    func listenPostcards(circleId: String, onChange: @escaping ([Postcard]) -> Void) -> ListenerRegistration? {
        guard configured else {
            onChange([])
            return nil
        }
        return postcards(circleId)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, _ in
                let cards = snapshot?.documents.compactMap { try? $0.data(as: Postcard.self) } ?? []
                onChange(cards)
            }
    }

    // Whoever ends the hangout frames the memory.
    @discardableResult
    func createPostcard(hangout: Hangout, framedBy: String, circleId: String) async throws -> String {
        guard configured, let hangoutId = hangout.id else { throw FirebaseManager.notConfiguredError }
        let postcard = Postcard(
            hangoutId: hangoutId,
            hangoutTitle: hangout.title,
            templateId: "classic",
            blocks: [],
            contributorIds: [framedBy],
            createdAt: Date(),
            sealsAt: Date().addingTimeInterval(Self.sealWindow),
            framedBy: framedBy
        )
        let ref = try postcards(circleId).addDocument(from: postcard)
        return ref.documentID
    }

    func addBlock(_ block: PostcardBlock, postcardId: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await postcards(circleId).document(postcardId).updateData([
            "blocks": FieldValue.arrayUnion([[
                "id": block.id,
                "type": block.type.rawValue,
                "content": block.content,
                "authorId": block.authorId,
                "position": block.position,
            ]]),
            "contributorIds": FieldValue.arrayUnion([block.authorId]),
        ])
    }

    // Lock the postcard until a future date: a Time Capsule.
    func setTimeCapsule(postcardId: String, unlockAt: Date?, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await postcards(circleId).document(postcardId).updateData([
            "unlockAt": unlockAt.map { Timestamp(date: $0) } ?? FieldValue.delete()
        ])
    }
}
