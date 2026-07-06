import Foundation
import FirebaseFirestore

// Firestore: circles/{circleId}/stamps/{stampId}
nonisolated struct Stamp: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var userId: String
    var kind: StampKind
    var hangoutId: String?
    var awardedAt: Date
}

nonisolated enum StampKind: String, Codable, CaseIterable {
    case firstOneIn
    case host
    case scribe

    var title: String {
        switch self {
        case .firstOneIn: return "First One In"
        case .host: return "The Host"
        case .scribe: return "The Scribe"
        }
    }

    var emoji: String {
        switch self {
        case .firstOneIn: return "🏃"
        case .host: return "🎪"
        case .scribe: return "✍️"
        }
    }

    var blurb: String {
        switch self {
        case .firstOneIn: return "showed up before everyone. suspiciously punctual"
        case .host: return "made the plan actually happen"
        case .scribe: return "kept the memory alive on the postcard"
        }
    }
}
