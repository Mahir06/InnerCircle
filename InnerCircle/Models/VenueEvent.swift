import Foundation

// A bookable real-world event/venue (dummy catalog for now; the
// repository seam swaps in a places/events API later without UI changes).
nonisolated struct VenueEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let emoji: String
    let category: String
    let venue: String
    let area: String
    let startsAt: Date
    let pricePerHead: Int
    let hype: String

    var priceLabel: String {
        pricePerHead == 0 ? "free" : "₹\(pricePerHead)/head"
    }
}

// A confirmed (pretend) booking attached to a Hangout.
nonisolated struct VenueBooking: Codable, Equatable {
    var eventId: String
    var eventTitle: String
    var venue: String
    var bookingCode: String
    var bookedBy: String
    var bookedAt: Date
}
