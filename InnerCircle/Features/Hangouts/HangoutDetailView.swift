import SwiftUI

struct HangoutDetailView: View {
    let hangoutId: String
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: HangoutsViewModel

    @State private var newPotluckItem = ""
    @State private var newTask = ""
    @State private var editingPoster = false

    private var isHost: Bool {
        vm.hangout(hangoutId)?.hostId == appState.authUid
    }

    var body: some View {
        if let hangout = vm.hangout(hangoutId) {
            ScrollView {
                VStack(spacing: 18) {
                    poster(hangout)

                    if editingPoster {
                        PosterEditor(hangout: hangout) { editingPoster = false }
                    }

                    requestBanner(hangout)
                    shortlistSection(hangout)
                    rsvpSection(hangout)
                    detailsSection(hangout)
                    potluckSection(hangout)
                    tasksSection(hangout)
                    liveSection(hangout)
                }
                .padding(16)
            }
            .navigationTitle(hangout.title)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            Text("this hangout vanished. spooky")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: poster

    private func poster(_ hangout: Hangout) -> some View {
        VStack(spacing: 8) {
            Text(hangout.poster.emoji).font(.system(size: 56))
            Text(hangout.title)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            if let startsAt = hangout.startsAt {
                Text(startsAt.formatted(date: .complete, time: .shortened))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
            }
            HStack(spacing: 14) {
                if let place = hangout.place {
                    Label(place, systemImage: "mappin")
                }
                if let cost = hangout.estCost {
                    Label("₹\(Int(cost))/head", systemImage: "banknote")
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.9))
            if isHost && hangout.status == .planning {
                Button("edit poster") { editingPoster.toggle() }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Theme.colorway(hangout.poster.colorway), in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: request mode

    @ViewBuilder
    private func requestBanner(_ hangout: Hangout) -> some View {
        if hangout.mode == .request, hangout.requestStatus == .pending {
            if hangout.requestedFrom == appState.authUid {
                VStack(spacing: 10) {
                    Text("🫵 you've been chosen")
                        .font(.headline)
                    Text("\(appState.memberName(hangout.hostId)) wants YOU to plan this one")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("challenge accepted") {
                        vm.acceptPlanRequest(hangout)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 16))
            } else {
                Text("waiting for \(appState.memberName(hangout.requestedFrom ?? "")) to accept the mission...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: randomizer shortlist

    @ViewBuilder
    private func shortlistSection(_ hangout: Hangout) -> some View {
        if hangout.mode == .randomizer, let shortlist = hangout.shortlist,
           !shortlist.isEmpty, hangout.status == .planning {
            sectionCard("🎲 the shortlist") {
                ForEach(shortlist) { idea in
                    let voted = idea.votes.contains(appState.authUid ?? "")
                    Button {
                        vm.voteShortlist(hangout, ideaId: idea.id)
                    } label: {
                        HStack {
                            Image(systemName: voted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(voted ? Theme.accent : .secondary)
                            Text(idea.idea)
                            Spacer()
                            Text("\(idea.votes.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                if isHost {
                    Button("lock in the winner") {
                        vm.lockInShortlistWinner(hangout)
                    }
                    .font(.subheadline.bold())
                    .disabled(shortlist.allSatisfy { $0.votes.isEmpty })
                }
            }
        }
    }

    // MARK: rsvp

    private func rsvpSection(_ hangout: Hangout) -> some View {
        sectionCard("who's in?") {
            HStack(spacing: 10) {
                rsvpButton(hangout, .going, "going 🙌")
                rsvpButton(hangout, .maybe, "maybe 🤔")
                rsvpButton(hangout, .nope, "nope 🙃")
            }
            ForEach(RSVP.allCases, id: \.self) { answer in
                let people = hangout.rsvps.filter { $0.value == answer }.keys.map { appState.memberName($0) }
                if !people.isEmpty {
                    HStack(alignment: .top) {
                        Text(label(for: answer))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .leading)
                        Text(people.joined(separator: ", "))
                            .font(.caption)
                    }
                }
            }
        }
    }

    private func label(for rsvp: RSVP) -> String {
        switch rsvp {
        case .going: return "going"
        case .maybe: return "maybe"
        case .nope: return "nope"
        }
    }

    private func rsvpButton(_ hangout: Hangout, _ answer: RSVP, _ title: String) -> some View {
        let selected = hangout.rsvps[appState.authUid ?? ""] == answer
        return Button {
            vm.rsvp(hangout, answer)
        } label: {
            Text(title)
                .font(.footnote.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(selected ? Theme.accent : Theme.card.opacity(0.6),
                            in: Capsule())
                .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: details

    @ViewBuilder
    private func detailsSection(_ hangout: Hangout) -> some View {
        if let itemId = hangout.bucketListItemId,
           let item = appState.circle?.bucketList.first(where: { $0.id == itemId }) {
            HStack {
                Text("🪣")
                Text("this one checks off: **\(item.label)**")
                    .font(.footnote)
                Spacer()
            }
            .padding(12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: potluck

    private func potluckSection(_ hangout: Hangout) -> some View {
        sectionCard("🍱 potluck") {
            if hangout.potluck.isEmpty {
                Text("nothing on the list. someone's bringing nothing?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(hangout.potluck) { item in
                HStack {
                    Text(item.label)
                    Spacer()
                    if let claimedBy = item.claimedBy {
                        Button {
                            vm.togglePotluckClaim(hangout, itemId: item.id)
                        } label: {
                            Text(claimedBy == appState.authUid ? "you got it ✅" : appState.memberName(claimedBy))
                                .font(.caption.bold())
                                .foregroundStyle(claimedBy == appState.authUid ? Theme.accent : .secondary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button("i'll bring it") {
                            vm.togglePotluckClaim(hangout, itemId: item.id)
                        }
                        .font(.caption.bold())
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 2)
            }
            HStack {
                TextField("add something to bring", text: $newPotluckItem)
                    .font(.footnote)
                Button("add") {
                    vm.addPotluckItem(hangout, label: newPotluckItem)
                    newPotluckItem = ""
                }
                .font(.caption.bold())
                .disabled(newPotluckItem.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: tasks

    private func tasksSection(_ hangout: Hangout) -> some View {
        sectionCard("✅ tasks") {
            if hangout.tasks.isEmpty {
                Text("no tasks. bold strategy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(hangout.tasks) { task in
                Button {
                    vm.toggleTaskDone(hangout, taskId: task.id)
                } label: {
                    HStack {
                        Image(systemName: task.done ? "checkmark.square.fill" : "square")
                            .foregroundStyle(task.done ? Theme.accent : .secondary)
                        Text(task.label)
                            .strikethrough(task.done)
                        Spacer()
                        if let assignedTo = task.assignedTo {
                            Text(appState.memberName(assignedTo))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
            HStack {
                TextField("add a task", text: $newTask)
                    .font(.footnote)
                Button("add") {
                    vm.addTask(hangout, label: newTask, assignedTo: nil)
                    newTask = ""
                }
                .font(.caption.bold())
                .disabled(newTask.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: live / lifecycle

    @ViewBuilder
    private func liveSection(_ hangout: Hangout) -> some View {
        switch hangout.status {
        case .planning:
            if isHost {
                Button {
                    vm.startHangout(hangout)
                } label: {
                    Text("start the hangout 🚀")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
            }
        case .live:
            sectionCard("🔴 it's happening") {
                if hangout.arrivals[appState.authUid ?? ""] == nil {
                    Button {
                        vm.markArrival(hangout)
                    } label: {
                        Text("i'm here! 📍")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                let arrivals = hangout.arrivals.sorted { $0.value < $1.value }
                ForEach(Array(arrivals.enumerated()), id: \.element.key) { index, arrival in
                    HStack {
                        Text(index == 0 ? "🏃" : "👋")
                        Text(appState.memberName(arrival.key))
                        if index == 0 {
                            Text("first one in!")
                                .font(.caption2.bold())
                                .foregroundStyle(Theme.accent)
                        }
                        Spacer()
                        Text(arrival.value.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    GameShelfView()
                } label: {
                    Label("start an offline game", systemImage: "gamecontroller.fill")
                        .font(.subheadline.bold())
                }
                if isHost {
                    Button("end hangout (postcard time)") {
                        vm.endHangout(hangout)
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                }
            }
        case .done:
            VStack(spacing: 6) {
                Text("🎉 that's a wrap")
                    .font(.headline)
                Text("check the Mailbox for the postcard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: helpers

    private func sectionCard(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Poster editor

private struct PosterEditor: View {
    let hangout: Hangout
    let onDone: () -> Void
    @EnvironmentObject var vm: HangoutsViewModel

    @State private var emoji: String
    @State private var colorway: String

    private let emojiChoices = ["🎉", "🍛", "🌊", "🎬", "🎲", "⛰️", "🍕", "🎤", "☕️", "🧺", "🏏", "🌃"]

    init(hangout: Hangout, onDone: @escaping () -> Void) {
        self.hangout = hangout
        self.onDone = onDone
        _emoji = State(initialValue: hangout.poster.emoji)
        _colorway = State(initialValue: hangout.poster.colorway)
    }

    var body: some View {
        VStack(spacing: 12) {
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
            Button("save poster") {
                vm.updatePoster(hangout, poster: Poster(templateId: hangout.poster.templateId, colorway: colorway, emoji: emoji))
                onDone()
            }
            .font(.subheadline.bold())
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}
