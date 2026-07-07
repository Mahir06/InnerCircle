import Foundation
import Combine
import FirebaseFirestore

// Session-level state: who is signed in, which circle they belong to,
// and which top-level screen the app should show.
@MainActor
final class AppState: ObservableObject {
    enum Phase: Equatable {
        case loading
        case signedOut
        case needsProfile     // auth account exists, user doc doesn't
        case needsCircle      // signed in, but hasn't created/joined a circle
        case ready            // signed in + in a circle
    }

    @Published var phase: Phase = .loading
    @Published var authUid: String?
    @Published var currentUser: AppUser?
    @Published var circle: FriendCircle?
    @Published var members: [AppUser] = []

    let backendConnected = FirebaseManager.shared.isConfigured

    let authRepo = AuthRepository()
    let userRepo = UserRepository()
    let circleRepo = CircleRepository()

    private var userListener: ListenerRegistration?
    private var circleListener: ListenerRegistration?
    private var membersListener: ListenerRegistration?
    private var listeningCircleId: String?

    init() {
        if DemoContent.isActive {
            authUid = DemoContent.userId
            currentUser = DemoContent.user
            circle = DemoContent.circle
            members = DemoContent.members
            phase = .ready
            return
        }
        guard backendConnected else {
            phase = .signedOut
            return
        }
        authRepo.listenAuthState { [weak self] uid in
            Task { @MainActor in
                self?.handleAuthChange(uid: uid)
            }
        }
    }

    func member(_ userId: String) -> AppUser? {
        members.first { $0.id == userId }
    }

    func memberName(_ userId: String) -> String {
        member(userId)?.displayName ?? "someone"
    }

    func signOut() {
        try? authRepo.signOut()
    }

    private func handleAuthChange(uid: String?) {
        detachUser()
        detachCircle()
        authUid = uid
        currentUser = nil
        circle = nil
        members = []

        guard let uid else {
            phase = .signedOut
            return
        }
        phase = .loading
        userListener = userRepo.listenUser(uid: uid) { [weak self] user in
            Task { @MainActor in
                self?.handleUserChange(user)
            }
        }
    }

    private func handleUserChange(_ user: AppUser?) {
        currentUser = user
        guard let user else {
            detachCircle()
            phase = .needsProfile
            return
        }
        if let circleId = user.circleId {
            if listeningCircleId != circleId {
                detachCircle()
                listeningCircleId = circleId
                circleListener = circleRepo.listenCircle(id: circleId) { [weak self] circle in
                    Task { @MainActor in
                        self?.circle = circle
                        if circle != nil { self?.phase = .ready }
                    }
                }
                membersListener = circleRepo.listenMembers(circleId: circleId) { [weak self] members in
                    Task { @MainActor in
                        self?.members = members
                    }
                }
            }
        } else {
            detachCircle()
            phase = .needsCircle
        }
    }

    private func detachUser() {
        userListener?.remove()
        userListener = nil
    }

    private func detachCircle() {
        circleListener?.remove()
        circleListener = nil
        membersListener?.remove()
        membersListener = nil
        listeningCircleId = nil
    }
}
