import SwiftUI

// Real-world plans: browse what's on nearby, grab (pretend) tickets, and
// it lands in Hangouts fully filled in with the booking attached.
struct DiscoverView: View {
    let onBooked: () -> Void
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: HangoutsViewModel

    private let repo = EventsRepository()
    @State private var category = "all"
    @State private var selectedEvent: VenueEvent?

    private var events: [VenueEvent] {
        let all = repo.nearbyEvents()
        return category == "all" ? all : all.filter { $0.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("exciting things around you. all bookings are pretend (for now), the plans are real")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(repo.categories, id: \.self) { cat in
                            Button {
                                category = cat
                            } label: {
                                Text(cat)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(cat == category ? Theme.accent : Theme.card, in: Capsule())
                                    .foregroundStyle(cat == category ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                ForEach(events) { event in
                    Button {
                        selectedEvent = event
                    } label: {
                        EventCard(event: event)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .navigationTitle("out there")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event) {
                selectedEvent = nil
                onBooked()
            }
            .environmentObject(appState)
            .environmentObject(vm)
        }
    }
}

private struct EventCard: View {
    let event: VenueEvent

    var body: some View {
        HStack(spacing: 12) {
            Text(event.emoji)
                .font(.system(size: 32))
                .frame(width: 60, height: 60)
                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title).font(.subheadline.bold()).lineLimit(1)
                Text("\(event.venue) · \(event.area)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(event.startsAt.formatted(.dateTime.weekday(.wide).day().month().hour()))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(event.priceLabel)
                    .font(.caption.bold())
                    .foregroundStyle(Theme.accent)
                Text("book")
                    .font(.caption2.weight(.heavy))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct EventDetailSheet: View {
    let event: VenueEvent
    let onDone: () -> Void
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: HangoutsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var bookingCode: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let code = bookingCode {
                    // the ticket stub
                    Spacer()
                    Text("🎟️").font(.system(size: 56))
                    Text("you're in!").font(.title2.bold())
                    VStack(spacing: 6) {
                        Text(event.title).font(.headline)
                        Text("\(event.venue) · \(event.area)").font(.caption).foregroundStyle(.secondary)
                        Text(event.startsAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(code)
                            .font(.system(.title2, design: .monospaced).bold())
                            .kerning(2)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
                    Text("it's on the Hangouts tab with the booking attached. invite dropped in chat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    bigButton("done") {
                        dismiss()
                        onDone()
                    }
                    Spacer()
                } else {
                    Spacer()
                    Text(event.emoji).font(.system(size: 64))
                    Text(event.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(event.hype)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    VStack(spacing: 4) {
                        Label("\(event.venue) · \(event.area)", systemImage: "mappin")
                        Label(event.startsAt.formatted(.dateTime.weekday(.wide).day().month().hour()), systemImage: "clock")
                        Label(event.priceLabel, systemImage: "banknote")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    bigButton("grab tickets 🎟️") { book() }
                        .padding(.horizontal, 24)
                    Text("(pretend booking. real API coming)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
            .padding(16)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") { dismiss() }
                }
            }
        }
    }

    private func book() {
        guard let uid = appState.authUid else { return }
        let code = EventsRepository.generateBookingCode()
        var hangout = Hangout.new(title: event.title, hostId: uid, mode: .custom)
        hangout.place = "\(event.venue), \(event.area)"
        hangout.startsAt = event.startsAt
        hangout.estCost = Double(event.pricePerHead)
        hangout.poster = Poster(templateId: "ticket", colorway: colorway(for: event.category), emoji: event.emoji)
        hangout.venueBooking = VenueBooking(
            eventId: event.id,
            eventTitle: event.title,
            venue: event.venue,
            bookingCode: code,
            bookedBy: uid,
            bookedAt: Date()
        )
        vm.create(hangout)
        bookingCode = code
    }

    private func colorway(for category: String) -> String {
        switch category {
        case "music": return "grape"
        case "food": return "mango"
        case "games": return "sky"
        case "outdoors": return "mint"
        default: return "bubblegum"
        }
    }
}
