import Foundation
import FirebaseFirestore

// Firestore: circles/{circleId}
// Named FriendCircle (not Circle) to avoid clashing with SwiftUI.Circle in views.
nonisolated struct FriendCircle: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var name: String
    var coverEmoji: String
    var coverUrl: String?
    var bannerUrl: String?
    var code: String            // the Group Ticket, 6-char uppercase, indexed
    var memberIds: [String]
    var bucketList: [BucketListItem]
    var stats: CircleStats
    var quotesArchive: [SavedQuote]
    var createdAt: Date

    static let maxMembers = 10

    static func new(name: String, coverEmoji: String, creatorId: String) -> FriendCircle {
        FriendCircle(
            name: name,
            coverEmoji: coverEmoji,
            code: FriendCircle.generateGroupTicket(),
            memberIds: [creatorId],
            bucketList: [],
            stats: CircleStats(hangoutsCompleted: 0, restaurantsVisited: 0, placesVisited: 0),
            quotesArchive: [],
            createdAt: Date()
        )
    }

    // No 0/O/1/I so nobody squints at the ticket
    static func generateGroupTicket() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in alphabet.randomElement()! })
    }
}

nonisolated struct BucketListItem: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var done: Bool
    var doneHangoutId: String?
}

nonisolated struct CircleStats: Codable, Equatable {
    var hangoutsCompleted: Int
    var restaurantsVisited: Int
    var placesVisited: Int
}

// "hall of fame" quotes saved from chat
nonisolated struct SavedQuote: Codable, Identifiable, Equatable {
    var id: String
    var text: String
    var authorId: String
    var savedBy: String
    var at: Date
}
