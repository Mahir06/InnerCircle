import Foundation
import FirebaseFirestore

// Firestore: circles/{circleId}/messages/{messageId}
// Drops are dynamic chat message types.
nonisolated struct Message: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var senderId: String
    var sentAt: Date
    var type: DropType
    var text: String?
    var poll: Poll?
    var hangoutId: String?
    var gameSessionId: String?
    var spark: SparkDrop?
    var reactions: [String: [String]]?   // emoji -> userIds who reacted
}

nonisolated enum DropType: String, Codable {
    case text, poll, hangoutInvite, gameInvite, spark, system
}

nonisolated struct Poll: Codable, Equatable {
    var question: String
    var allowsMultipleAnswers: Bool
    var options: [PollOption]

    var totalVotes: Int { options.reduce(0) { $0 + $1.voterIds.count } }
}

nonisolated struct PollOption: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var voterIds: [String]
}

// A Spark dropped into chat; answers keyed by userId
nonisolated struct SparkDrop: Codable, Equatable {
    var promptId: String
    var prompt: String
    var kind: String?
    var answers: [String: String]
}
