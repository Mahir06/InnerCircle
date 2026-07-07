import Foundation
import FirebaseFirestore

// Firestore: circles/{circleId}/postcards/{postcardId}
// Collaborative memory artifact created after a Hangout.
nonisolated struct Postcard: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var hangoutId: String
    var hangoutTitle: String?            // denormalized so the Mailbox needs no joins
    var templateId: String
    var blocks: [PostcardBlock]
    var contributorIds: [String]
    var createdAt: Date
    var sealsAt: Date                    // the envelope-sealing deadline
    var sealedAt: Date?
    var unlockAt: Date?                  // set = this is a Time Capsule
    var framedBy: String?                // "mahir framed the memory"

    var isSealed: Bool { sealedAt != nil || Date() >= sealsAt }
    var isLockedCapsule: Bool {
        if let unlockAt { return Date() < unlockAt }
        return false
    }
}

nonisolated struct PostcardBlock: Codable, Identifiable, Equatable {
    var id: String
    var type: BlockType
    var content: String                  // text, photo URL, or sticker emoji
    var authorId: String
    var position: Int
}

nonisolated enum BlockType: String, Codable {
    case text, photo, sticker
    case badge          // a stamp earned at this hangout, framed in the journal
    case aiSummary      // the AI scribe's recap of the hangout chat
}
