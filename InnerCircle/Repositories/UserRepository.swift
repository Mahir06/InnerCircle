import Foundation
import FirebaseFirestore

// Firestore access for users/{userId}
final class UserRepository {
    private var db: Firestore { FirebaseManager.shared.db }
    private var configured: Bool { FirebaseManager.shared.isConfigured }

    func createUser(_ user: AppUser, uid: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try db.collection("users").document(uid).setData(from: user)
    }

    // onChange(nil) means the user doc doesn't exist yet (fresh signup)
    func listenUser(uid: String, onChange: @escaping (AppUser?) -> Void) -> ListenerRegistration? {
        guard configured else {
            onChange(nil)
            return nil
        }
        return db.collection("users").document(uid).addSnapshotListener { snapshot, _ in
            onChange(try? snapshot?.data(as: AppUser.self))
        }
    }

    func updateIDCard(_ idCard: IDCard, uid: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await db.collection("users").document(uid).updateData([
            "idCard": ["color": idCard.color, "emoji": idCard.emoji, "tagline": idCard.tagline]
        ])
    }

    func updateStatus(_ status: UserStatus, uid: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await db.collection("users").document(uid).updateData([
            "status": ["text": status.text, "emoji": status.emoji, "setAt": Timestamp(date: status.setAt)]
        ])
    }
}
