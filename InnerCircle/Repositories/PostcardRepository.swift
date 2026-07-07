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

    // The postcard born from a specific hangout (used by the hangout chat's
    // "seal the story" action).
    func fetchPostcard(hangoutId: String, circleId: String) async throws -> Postcard? {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let snapshot = try await postcards(circleId)
            .whereField("hangoutId", isEqualTo: hangoutId)
            .limit(to: 1)
            .getDocuments()
        return try snapshot.documents.first?.data(as: Postcard.self)
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

    // Photos live as compressed base64 in one-doc-per-photo media docs so
    // the journal works on the free plan (Storage needs Blaze). A photo
    // block's content is "media:<mediaId>".
    func addMedia(_ jpegData: Data, postcardId: String, circleId: String) async throws -> String {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let ref = postcards(circleId).document(postcardId).collection("media").document()
        try await ref.setData([
            "data": jpegData.base64EncodedString(),
            "contentType": "image/jpeg",
            "createdAt": Timestamp(date: Date()),
        ])
        return ref.documentID
    }

    func fetchMedia(mediaId: String, postcardId: String, circleId: String) async throws -> Data? {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let doc = try await postcards(circleId).document(postcardId)
            .collection("media").document(mediaId).getDocument()
        guard let base64 = doc.data()?["data"] as? String else { return nil }
        return Data(base64Encoded: base64)
    }

    // Contributors can pull their own block back before the envelope seals.
    func removeBlock(blockId: String, postcardId: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let ref = postcards(circleId).document(postcardId)
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard var blocks = snapshot.data()?["blocks"] as? [[String: Any]] else { return nil }
                blocks.removeAll { $0["id"] as? String == blockId }
                transaction.updateData(["blocks": blocks], forDocument: ref)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    // Lock the postcard until a future date: a Time Capsule.
    func setTimeCapsule(postcardId: String, unlockAt: Date?, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await postcards(circleId).document(postcardId).updateData([
            "unlockAt": unlockAt.map { Timestamp(date: $0) } ?? FieldValue.delete()
        ])
    }
}
