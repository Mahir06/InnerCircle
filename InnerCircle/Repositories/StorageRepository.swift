import Foundation
import FirebaseStorage

// Firebase Storage uploads. Paths mirror the security rules.
final class StorageRepository {
    private var storage: Storage { FirebaseManager.shared.storage }
    private var configured: Bool { FirebaseManager.shared.isConfigured }

    func uploadPostcardPhoto(_ data: Data, circleId: String, postcardId: String) async throws -> URL {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let ref = storage.reference()
            .child("circles/\(circleId)/postcards/\(postcardId)/\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }
}
