import Foundation
import FirebaseFirestore

// Firestore: circles/{circleId}/hangouts/{hangoutId}
nonisolated struct Hangout: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var title: String
    var hostId: String
    var startsAt: Date?
    var place: String?
    var status: HangoutStatus
    var mode: HangoutMode
    var poster: Poster
    var rsvps: [String: RSVP]            // userId -> going / maybe / nope
    var arrivals: [String: Date]         // userId -> arrived at (for First One In)
    var potluck: [PotluckItem]
    var tasks: [HangoutTask]
    var estCost: Double?
    var bucketListItemId: String?
    var requestedFrom: String?           // request mode: who was asked to plan
    var requestStatus: RequestStatus?
    var shortlist: [ShortlistIdea]?      // randomizer mode vote list
    var venueBooking: VenueBooking?      // set when booked through Discover
    var createdAt: Date

    static func new(title: String, hostId: String, mode: HangoutMode) -> Hangout {
        Hangout(
            title: title,
            hostId: hostId,
            status: .planning,
            mode: mode,
            poster: Poster(templateId: "classic", colorway: "sunset", emoji: "🎉"),
            rsvps: [hostId: .going],
            arrivals: [:],
            potluck: [],
            tasks: [],
            createdAt: Date()
        )
    }
}

nonisolated enum HangoutStatus: String, Codable {
    case planning, live, done
}

nonisolated enum HangoutMode: String, Codable {
    case custom, howAboutWe, request, randomizer
}

nonisolated enum RSVP: String, Codable, CaseIterable {
    case going, maybe, nope
}

nonisolated enum RequestStatus: String, Codable {
    case pending, accepted
}

// The editable invite artifact for a Hangout
nonisolated struct Poster: Codable, Equatable {
    var templateId: String
    var colorway: String
    var emoji: String
}

nonisolated struct PotluckItem: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var claimedBy: String?
}

nonisolated struct HangoutTask: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var assignedTo: String?
    var done: Bool
}

nonisolated struct ShortlistIdea: Codable, Identifiable, Equatable {
    var id: String
    var idea: String
    var votes: [String]                  // userIds
}
