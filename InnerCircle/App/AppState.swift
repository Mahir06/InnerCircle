import Foundation
import Combine

// Session-level state: who is signed in, which circle they belong to,
// and which top-level screen the app should show.
@MainActor
final class AppState: ObservableObject {
    enum Phase: Equatable {
        case loading
        case signedOut
        case needsCircle      // signed in, but hasn't created/joined a circle
        case ready            // signed in + in a circle
    }

    @Published var phase: Phase = .loading
    @Published var currentUser: AppUser?
    @Published var circle: FriendCircle?

    let backendConnected = FirebaseManager.shared.isConfigured

    init() {
        // Auth state listening arrives with the auth block; until then
        // everyone starts signed out.
        phase = .signedOut
    }
}
