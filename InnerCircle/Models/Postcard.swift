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
    var content: String                  // text, photo pointer, sticker emoji, or doodle path data
    var authorId: String
    var position: Int

    // collage canvas placement (normalized 0-1; legacy blocks get a
    // deterministic scatter so old postcards still look collaged)
    var x: Double?
    var y: Double?
    var rotation: Double?                // degrees
    var scale: Double?
    var z: Int?
}

nonisolated enum BlockType: String, Codable {
    case text, photo, sticker
    case badge          // a stamp earned at this hangout, framed in the journal
    case aiSummary      // the AI scribe's recap of the hangout chat
    case doodle         // finger drawing: "colorway|x,y x,y;x,y ..." normalized strokes
}
