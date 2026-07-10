import SwiftUI

struct HangoutsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = HangoutsViewModel()
    @State private var showModePicker = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.hangouts.isEmpty {
                    VStack(spacing: 8) {
                        Illustration(slot: "empty-hangouts")
                        Text(Copy.hangoutsEmpty).foregroundStyle(.secondary)
                        Button("plan something") { showModePicker = true }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(vm.hangouts) { hangout in
                                NavigationLink(value: hangout.id ?? "") {
                                    HangoutCard(hangout: hangout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Hangouts")
            .navigationDestination(for: String.self) { hangoutId in
                HangoutDetailView(hangoutId: hangoutId)
                    .environmentObject(vm)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showModePicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showModePicker) {
                PlanModePickerSheet()
                    .environmentObject(vm)
            }
            .onAppear {
                if let circleId = appState.circle?.id, let uid = appState.authUid {
                    vm.start(circleId: circleId, userId: uid)
                }
            }
            if let error = vm.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).padding(.horizontal)
            }
        }
    }
}

// MARK: - Card

struct HangoutCard: View {
    let hangout: Hangout
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 14) {
            Text(hangout.poster.emoji)
                .font(.system(size: 34))
                .frame(width: 62, height: 62)
                .background(Theme.colorway(hangout.poster.colorway).opacity(0.25),
                            in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(hangout.title).font(.headline).lineLimit(1)
                    statusBadge
                }
                if let startsAt = hangout.startsAt {
                    Text(startsAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    let going = hangout.rsvps.values.filter { $0 == .going }.count
                    Text("\(going) going")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.accent)
                    if hangout.mode == .request && hangout.requestStatus == .pending {
                        Text("· waiting on \(appState.memberName(hangout.requestedFrom ?? ""))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch hangout.status {
        case .planning:
            EmptyView()
        case .live:
            Text("LIVE")
                .font(.caption2.weight(.heavy))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.red.opacity(0.15), in: Capsule())
                .foregroundStyle(.red)
        case .done:
            Text("done")
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.green.opacity(0.15), in: Capsule())
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Mode picker

private struct PlanModePickerSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: HangoutsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var mode: HangoutMode?
    @State private var showDiscover = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                modeCard("🎟️", "something real", "gigs, treks, escape rooms. book it, it becomes the plan") { showDiscover = true }
                modeCard("✍️", "make your own plan", "you know exactly what you want. respect") { mode = .custom }
                modeCard("💡", "how about we...", "curated ideas for the chronically indecisive") { mode = .howAboutWe }
                modeCard("🫵", "ask someone to plan", "delegate. it's called leadership") { mode = .request }
                modeCard("🎲", "not sure? shortlist it", "throw ideas in, everyone votes, democracy wins") { mode = .randomizer }
                Spacer()
            }
            .navigationDestination(isPresented: $showDiscover) {
                DiscoverView(onBooked: { dismiss() })
            }
            .padding(20)
            .navigationTitle("plan a hangout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
            }
            .navigationDestination(item: $mode) { mode in
                switch mode {
                case .custom:
                    CreateHangoutForm(mode: .custom, presetTitle: nil, onDone: { dismiss() })
                case .howAboutWe:
                    HowAboutWeList(onDone: { dismiss() })
                case .request:
                    RequestPlanForm(onDone: { dismiss() })
                case .randomizer:
                    RandomizerForm(onDone: { dismiss() })
                }
            }
        }
    }

    private func modeCard(_ emoji: String, _ title: String, _ line: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji).font(.system(size: 30))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(line).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

extension HangoutMode: Identifiable {
    var id: String { rawValue }
}

// MARK: - Create form (custom + howAboutWe presets land here)

struct CreateHangoutForm: View {
    let mode: HangoutMode
    let presetTitle: String?
    let onDone: () -> Void

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: HangoutsViewModel

    @State private var title = ""
    @State private var emoji = "🎉"
    @State private var colorway = "sunset"
    @State private var hasDate = false
    @State private var startsAt = Date().addingTimeInterval(86400)
    @State private var place = ""
    @State private var estCost = ""
    @State private var bucketListItemId: String?

    private let emojiChoices = ["🎉", "🍛", "🌊", "🎬", "🎲", "⛰️", "🍕", "🎤", "☕️", "🧺", "🏏", "🌃"]

    var body: some View {
        Form {
            Section("the plan") {
                TextField("what are we doing?", text: $title)
                TextField("where? (optional)", text: $place)
                Toggle("pick a date", isOn: $hasDate)
                if hasDate {
                    DatePicker("when", selection: $startsAt)
                }
                TextField("est. cost per head (optional)", text: $estCost)
                    .keyboardType(.numberPad)
            }
            Section("poster") {
                posterPreview
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(emojiChoices, id: \.self) { choice in
                        Text(choice)
                            .font(.system(size: 26))
                            .padding(4)
                            .background(choice == emoji ? Theme.accentSoft : .clear,
                                        in: RoundedRectangle(cornerRadius: 8))
                            .onTapGesture { emoji = choice }
                    }
                }
                HStack(spacing: 10) {
                    ForEach(Array(Theme.colorways.keys.sorted()), id: \.self) { key in
                        SwiftUI.Circle()
                            .fill(Theme.colorway(key))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if key == colorway {
                                    SwiftUI.Circle().strokeBorder(.white, lineWidth: 2.5)
                                }
                            }
                            .onTapGesture { colorway = key }
                    }
                }
            }
            if let bucketList = appState.circle?.bucketList.filter({ !$0.done }), !bucketList.isEmpty {
                Section("fulfills a bucket list dream?") {
                    Picker("bucket list item", selection: $bucketListItemId) {
                        Text("nope, just vibes").tag(String?.none)
                        ForEach(bucketList) { item in
                            Text(item.label).tag(String?.some(item.id))
                        }
                    }
                }
            }
            Section {
                Button("make it official") { create() }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle(mode == .howAboutWe ? "how about we..." : "new hangout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let presetTitle, title.isEmpty { title = presetTitle }
        }
    }

    private var posterPreview: some View {
        VStack(spacing: 6) {
            Text(emoji).font(.system(size: 44))
            Text(title.isEmpty ? "the plan" : title)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            if hasDate {
                Text(startsAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Theme.colorway(colorway), in: RoundedRectangle(cornerRadius: 16))
    }

    private func create() {
        guard let uid = appState.authUid else { return }
        var hangout = Hangout.new(title: title.trimmingCharacters(in: .whitespaces), hostId: uid, mode: mode)
        hangout.poster = Poster(templateId: "classic", colorway: colorway, emoji: emoji)
        hangout.place = place.isEmpty ? nil : place
        hangout.startsAt = hasDate ? startsAt : nil
        hangout.estCost = Double(estCost)
        hangout.bucketListItemId = bucketListItemId
        vm.create(hangout)
        onDone()
    }
}

// MARK: - How about we

private struct HowAboutWeList: View {
    let onDone: () -> Void

    static let presets: [(emoji: String, title: String)] = [
        ("🫖", "chai crawl across the city"),
        ("🧺", "picnic but make it aesthetic"),
        ("🍿", "movie marathon, phones in a box"),
        ("🎲", "game night: friendships end tonight"),
        ("🌶️", "street food safari"),
        ("⛰️", "sunrise trek (we will regret this)"),
        ("🎳", "bowling, loser buys dinner"),
        ("🌊", "beach day, no agenda"),
        ("🎤", "karaoke, zero talent required"),
        ("☕️", "board game cafe takeover"),
    ]

    var body: some View {
        List(Self.presets, id: \.title) { preset in
            NavigationLink {
                CreateHangoutForm(mode: .howAboutWe, presetTitle: preset.title, onDone: onDone)
            } label: {
                HStack(spacing: 12) {
                    Text(preset.emoji).font(.title2)
                    Text(preset.title)
                }
            }
        }
        .navigationTitle("how about we...")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Request mode

private struct RequestPlanForm: View {
    let onDone: () -> Void
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: HangoutsViewModel
    @State private var chosen: String?

    var body: some View {
        List {
            Section {
                Text("pick your planner. they'll get the request and full hosting powers")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(appState.members.filter { $0.id != appState.authUid }) { member in
                Button {
                    chosen = member.id
                } label: {
                    HStack {
                        Text(member.idCard.emoji)
                        Text(member.displayName)
                        Spacer()
                        if chosen == member.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            Section {
                Button("send the request") { send() }
                    .disabled(chosen == nil)
            }
        }
        .navigationTitle("ask someone to plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() {
        guard let uid = appState.authUid, let chosen else { return }
        var hangout = Hangout.new(
            title: "mystery plan by \(appState.memberName(chosen))",
            hostId: uid,
            mode: .request
        )
        hangout.requestedFrom = chosen
        hangout.requestStatus = .pending
        vm.create(hangout)
        onDone()
    }
}

// MARK: - Randomizer mode

private struct RandomizerForm: View {
    let onDone: () -> Void
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: HangoutsViewModel

    @State private var ideas: [String] = []
    @State private var newIdea = ""

    private let suggestions = [
        "bowling", "picnic", "street food crawl", "movie night",
        "arcade takeover", "midnight drive", "museum speedrun",
    ]

    var body: some View {
        List {
            Section("the shortlist") {
                ForEach(ideas, id: \.self) { idea in
                    Text(idea)
                }
                .onDelete { ideas.remove(atOffsets: $0) }
                HStack {
                    TextField("add an idea", text: $newIdea)
                    Button("add") {
                        let trimmed = newIdea.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !ideas.contains(trimmed) {
                            ideas.append(trimmed)
                        }
                        newIdea = ""
                    }
                    .disabled(newIdea.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            Section("need inspiration?") {
                ForEach(suggestions.filter { !ideas.contains($0) }, id: \.self) { suggestion in
                    Button {
                        ideas.append(suggestion)
                    } label: {
                        Label(suggestion, systemImage: "plus")
                    }
                }
            }
            Section {
                Button("open voting") { create() }
                    .disabled(ideas.count < 2)
            } footer: {
                Text("everyone votes, top idea becomes the plan")
            }
        }
        .navigationTitle("shortlist it")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func create() {
        guard let uid = appState.authUid else { return }
        var hangout = Hangout.new(title: "the shortlist decides 🎲", hostId: uid, mode: .randomizer)
        hangout.shortlist = ideas.map { ShortlistIdea(id: UUID().uuidString, idea: $0, votes: []) }
        vm.create(hangout)
        onDone()
    }
}
