import Foundation
import FirebaseAuth

// All FirebaseAuth access. Views talk to AppState / view models, never here.
final class AuthRepository {
    private var manager: FirebaseManager { .shared }

    var currentUid: String? {
        guard manager.isConfigured else { return nil }
        return manager.auth.currentUser?.uid
    }

    func listenAuthState(_ onChange: @escaping (String?) -> Void) {
        guard manager.isConfigured else {
            onChange(nil)
            return
        }
        manager.auth.addStateDidChangeListener { _, user in
            onChange(user?.uid)
        }
    }

    func signUp(email: String, password: String) async throws -> String {
        guard manager.isConfigured else { throw FirebaseManager.notConfiguredError }
        let result = try await manager.auth.createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws -> String {
        guard manager.isConfigured else { throw FirebaseManager.notConfiguredError }
        let result = try await manager.auth.signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func sendPasswordReset(email: String) async throws {
        guard manager.isConfigured else { throw FirebaseManager.notConfiguredError }
        try await manager.auth.sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        guard manager.isConfigured else { return }
        try manager.auth.signOut()
    }
}
