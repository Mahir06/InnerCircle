import Foundation

// The Discover catalog. Dummy data from the bundle today; the interface
// is the seam where a real places/events API plugs in later.
final class EventsRepository {
    private static var cached: [VenueEvent]?

    func nearbyEvents() -> [VenueEvent] {
        if let cached = Self.cached { return cached }
        guard let url = Bundle.main.url(forResource: "events-seed", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = root["events"] as? [[String: Any]] else {
            return []
        }
        let calendar = Calendar.current
        let events = items.compactMap { item -> VenueEvent? in
            guard let id = item["id"] as? String,
                  let title = item["title"] as? String,
                  let emoji = item["emoji"] as? String,
                  let category = item["category"] as? String,
                  let venue = item["venue"] as? String,
                  let area = item["area"] as? String,
                  let daysFromNow = item["daysFromNow"] as? Int,
                  let hour = item["hour"] as? Int,
                  let price = item["pricePerHead"] as? Int,
                  let hype = item["hype"] as? String else { return nil }
            let day = calendar.date(byAdding: .day, value: daysFromNow, to: calendar.startOfDay(for: Date()))!
            let startsAt = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
            return VenueEvent(
                id: id, title: title, emoji: emoji, category: category,
                venue: venue, area: area, startsAt: startsAt,
                pricePerHead: price, hype: hype
            )
        }
        .sorted { $0.startsAt < $1.startsAt }
        Self.cached = events
        return events
    }

    var categories: [String] {
        ["all"] + Array(Set(nearbyEvents().map(\.category))).sorted()
    }

    static func generateBookingCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return "IC-" + String((0..<6).map { _ in alphabet.randomElement()! })
    }
}
