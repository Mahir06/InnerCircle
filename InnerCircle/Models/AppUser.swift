import Foundation
import FirebaseFirestore

// Firestore: users/{userId}
nonisolated struct AppUser: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var displayName: String
    var avatarUrl: String?
    var circleId: String?
    var idCard: IDCard
    var status: UserStatus?
    var createdAt: Date

    static func new(displayName: String) -> AppUser {
        AppUser(
            displayName: displayName,
            idCard: IDCard(color: "sunset", emoji: "🙂", tagline: "new here, be nice"),
            createdAt: Date()
        )
    }
}

// A member's customizable profile card
nonisolated struct IDCard: Codable, Equatable {
    var color: String
    var emoji: String
    var tagline: String
}

// "free to hangout" daily status
nonisolated struct UserStatus: Codable, Equatable {
    var text: String
    var emoji: String
    var setAt: Date
}
