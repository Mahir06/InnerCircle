import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Single gateway to Firebase. Views never touch this directly;
// repositories do, and views talk to repositories.
final class FirebaseManager {
    static let shared = FirebaseManager()

    // False when GoogleService-Info.plist is missing from the bundle.
    // The app still runs so the UI can be developed and demoed;
    // repositories surface a friendly "backend not wired up" error.
    let isConfigured: Bool

    private init() {
        if FirebaseApp.app() != nil {
            isConfigured = true
        } else if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
            isConfigured = true
        } else {
            isConfigured = false
            print("⚠️ Inner Circle: GoogleService-Info.plist not found. Drop it into the app target to light up the backend.")
        }
    }

    var db: Firestore { Firestore.firestore() }
    var auth: Auth { Auth.auth() }
    var storage: Storage { Storage.storage() }

    // Common error for repositories to throw when the plist is missing
    static var notConfiguredError: NSError {
        NSError(
            domain: "InnerCircle",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "the clubhouse has no wifi yet. add GoogleService-Info.plist to connect Firebase"]
        )
    }
}
