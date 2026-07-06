import Foundation
import FirebaseFirestore

// Firestore: sparks/{sparkId} — global pool of daily prompts
nonisolated struct Spark: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var prompt: String
    var kind: SparkKind
    var activeDate: String?              // "yyyy-MM-dd" when scheduled as the daily spark
}

nonisolated enum SparkKind: String, Codable, CaseIterable {
    case wouldYouRather
    case challenge
    case question

    var label: String {
        switch self {
        case .wouldYouRather: return "would you rather"
        case .challenge: return "challenge"
        case .question: return "question"
        }
    }
}
