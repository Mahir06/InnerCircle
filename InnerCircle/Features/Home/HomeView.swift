import SwiftUI

// The feed: everything alive in the circle, ranked by urgency.
// live hangout > games > expiring postcard > spark > poll > out there > memories
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: TabRouter
    @StateObject private var vm = HomeViewModel()
    @State private var showStatusSheet = false
    @State private var openSession: GameShelfView.SessionRef?
    @State private var showDiscover = false
    // demo tooling: IC_START_TAB=shelf lands straight on the Game Shelf
    @State private var showShelf = ProcessInfo.processInfo.environment["IC_START_TAB"] == "shelf"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statusBar

                    liveHangoutCard
                    gameCards
                    expiringPostcardCard
                    sparkCard
                    nextHangoutCard
                    pollCard
                    sparkResponsesCard
                    highlightsCard
                    eventCard
                    onThisDayCard
                    gameShelfCard
                }
                .padding(16)
            }
            .navigationTitle("yo, \(appState.currentUser?.displayName ?? "you")")
            .onAppear {
                if let circleId = appState.circle?.id, let uid = appState.authUid {
                    let names = Dictionary(uniqueKeysWithValues: appState.members.compactMap { m in
                        m.id.map { ($0, m.displayName) }
                    })
                    vm.start(circleId: circleId, userId: uid, memberName: { names[$0] ?? "someone" })
                }
            }
            .navigationDestination(isPresented: $showShelf) {
                GameShelfView()
            }
            .navigationDestination(isPresented: $showDiscover) {
                DiscoverDestination()
            }
            .sheet(isPresented: $showStatusSheet) {
                StatusSheet { text, emoji in
                    vm.setStatus(text: text, emoji: emoji)
                }
                .presentationDetents([.medium])
            }
            .sheet(item: $openSession) { ref in
                NavigationStack {
                    GameSessionView(sessionId: ref.id)
                }
            }
        }
    }

    // MARK: status bar

    private var statusBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(sortedMembers) { member in
                    let isMe = member.id == appState.authUid
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottomTrailing) {
                            Text(member.idCard.emoji)
                                .font(.system(size: 30))
                                .frame(width: 56, height: 56)
                                .background(Theme.colorway(member.idCard.color).opacity(0.25),
                                            in: SwiftUI.Circle())
                                .overlay(SwiftUI.Circle().strokeBorder(
                                    member.status != nil ? Theme.accent : .clear, lineWidth: 2.5))
                            if let status = member.status {
                                Text(status.emoji)
                                    .font(.system(size: 15))
                                    .offset(x: 3, y: 3)
                            }
                        }
                        Text(isMe ? "you" : member.displayName)
                            .font(.caption2.bold())
                        Text(member.status?.text ?? (isMe ? "set a status" : " "))
                            .font(.system(size: 9))
                            .foregroundStyle(isMe && member.status == nil ? Theme.accent : .secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 72)
                    }
                    .onTapGesture {
                        if isMe { showStatusSheet = true }
                    }
                }
            }
        }
    }

    private var sortedMembers: [AppUser] {
        appState.members.sorted { a, b in
            (a.id == appState.authUid ? 0 : 1) < (b.id == appState.authUid ? 0 : 1)
        }
    }

    // MARK: live hangout

    @ViewBuilder
    private var liveHangoutCard: some View {
        if let hangout = vm.liveHangout {
            FeedCard(
                emoji: hangout.poster.emoji,
                accent: .red,
                kicker: "🔴 HAPPENING NOW",
                title: hangout.title,
                line: "\(hangout.arrivals.count) already there. where are you?",
                cta: "i'm here"
            ) { router.selection = "hangouts" }
        }
    }

    // MARK: games

    @ViewBuilder
    private var gameCards: some View {
        if let lobby = vm.openLobby, let game = OnlineGame.byId(lobby.gameId) {
            FeedCard(
                emoji: game.emoji,
                accent: Theme.accent,
                kicker: "table is open",
                title: "\(game.title) needs players",
                line: "\(lobby.players.count) at the table, hosted by \(appState.memberName(lobby.hostId))",
                cta: "pull up a chair"
            ) {
                if let id = lobby.id { openSession = GameShelfView.SessionRef(id: id) }
            }
        }
        if let running = vm.runningGame, let game = OnlineGame.byId(running.gameId),
           running.players.contains(appState.authUid ?? "") {
            FeedCard(
                emoji: game.emoji,
                accent: Theme.colorway("grape"),
                kicker: "round \(running.round + 1) in progress",
                title: "\(game.title) is waiting on you",
                line: "the table doesn't move until everyone plays",
                cta: "back to the game"
            ) {
                if let id = running.id { openSession = GameShelfView.SessionRef(id: id) }
            }
        }
    }

    // MARK: postcard

    @ViewBuilder
    private var expiringPostcardCard: some View {
        if let postcard = vm.expiringPostcard {
            FeedCard(
                emoji: "✉️",
                accent: .orange,
                kicker: sealCountdown(postcard.sealsAt),
                title: postcard.hangoutTitle ?? "open postcard",
                line: "add your bit before the envelope seals forever",
                cta: "get on the collage"
            ) { router.selection = "mailbox" }
        }
    }

    // MARK: spark

    @ViewBuilder
    private var sparkCard: some View {
        if let spark = vm.todaySpark {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sparkles").foregroundStyle(.yellow)
                    Text("today's spark").font(.caption.bold()).foregroundStyle(.secondary)
                    Spacer()
                    Text(spark.kind.label)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.accentSoft, in: Capsule())
                }
                Text(spark.prompt)
                    .font(Theme.display(17, weight: .bold))
                HStack(spacing: 10) {
                    Button("answer in chat") { router.selection = "chat" }
                        .font(.caption.bold())
                        .buttonStyle(.bordered)
                    if spark.kind == .wouldYouRather {
                        Button("⚔️ make it a game") {
                            Task {
                                if let id = await vm.playSparkAsGame() {
                                    openSession = GameShelfView.SessionRef(id: id)
                                }
                            }
                        }
                        .font(.caption.bold())
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .chunkyCard()
        }
    }

    // MARK: upcoming hangout

    @ViewBuilder
    private var nextHangoutCard: some View {
        if vm.liveHangout == nil {
            if let hangout = vm.nextHangout {
                FeedCard(
                    emoji: hangout.poster.emoji,
                    accent: Theme.colorway(hangout.poster.colorway),
                    kicker: "next up",
                    title: hangout.title,
                    line: hangout.startsAt.map { $0.formatted(date: .abbreviated, time: .shortened) }
                        ?? "date TBD, classic",
                    cta: "RSVP"
                ) { router.selection = "hangouts" }
            } else {
                FeedCard(
                    emoji: "🗓️",
                    accent: Theme.accent,
                    kicker: "the calendar",
                    title: Copy.homeEmptyHangout,
                    line: "someone has to be the hero",
                    cta: "plan something"
                ) { router.selection = "hangouts" }
            }
        }
    }

    // MARK: poll + spark responses

    @ViewBuilder
    private var pollCard: some View {
        if let poll = vm.activePoll, let question = poll.poll?.question {
            FeedCard(
                emoji: "📊",
                accent: Theme.colorway("sky"),
                kicker: "\(poll.poll?.totalVotes ?? 0) votes in",
                title: question,
                line: "democracy needs you",
                cta: "vote"
            ) { router.selection = "chat" }
        }
    }

    @ViewBuilder
    private var sparkResponsesCard: some View {
        if let sparkDrop = vm.latestSparkDrop, let spark = sparkDrop.spark {
            FeedCard(
                emoji: "✨",
                accent: Theme.colorway("grape"),
                kicker: "\(spark.answers.count) answered",
                title: spark.prompt,
                line: "see what everyone said",
                cta: "peek"
            ) { router.selection = "chat" }
        }
    }

    // MARK: highlights

    @ViewBuilder
    private var highlightsCard: some View {
        if let highlights = vm.chatHighlights {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wand.and.stars").foregroundStyle(Theme.accent)
                    Text("the scribe's recap").font(.caption.bold()).foregroundStyle(.secondary)
                }
                Text(highlights)
                    .font(Theme.displayItalic(14))
                    .foregroundStyle(.primary)
                Button("catch up in chat") { router.selection = "chat" }
                    .font(.caption.bold())
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .chunkyCard(Theme.accentSoft)
        }
    }

    // MARK: out there

    @ViewBuilder
    private var eventCard: some View {
        if let event = vm.eventPick {
            FeedCard(
                emoji: event.emoji,
                accent: Theme.colorway("mango"),
                kicker: "out there · \(event.priceLabel)",
                title: event.title,
                line: "\(event.venue), \(event.area) · \(event.startsAt.formatted(.dateTime.weekday().day().month()))",
                cta: "see what's on"
            ) { showDiscover = true }
        }
    }

    // MARK: memories

    @ViewBuilder
    private var onThisDayCard: some View {
        if let memory = vm.onThisDay {
            FeedCard(
                emoji: "🗓️",
                accent: Theme.colorway("bubblegum"),
                kicker: "remember this?",
                title: memory.hangoutTitle ?? "a mystery memory",
                line: memory.createdAt.formatted(date: .long, time: .omitted),
                cta: "open the envelope"
            ) { router.selection = "mailbox" }
        }
    }

    private var gameShelfCard: some View {
        NavigationLink {
            GameShelfView()
        } label: {
            HStack(spacing: 12) {
                Text("🎴").font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text("the Game Shelf").font(Theme.cardTitle)
                    Text("4 online games + 10 party decks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(14)
            .chunkyCard()
        }
        .buttonStyle(.plain)
    }
}

// Wraps DiscoverView with its own HangoutsViewModel so bookings work
// when opened straight from Home.
private struct DiscoverDestination: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var hangoutsVM = HangoutsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DiscoverView(onBooked: { dismiss() })
            .environmentObject(hangoutsVM)
            .onAppear {
                if let circleId = appState.circle?.id, let uid = appState.authUid {
                    hangoutsVM.start(circleId: circleId, userId: uid)
                }
            }
    }
}

// MARK: - feed card + status sheet

private struct FeedCard: View {
    let emoji: String
    let accent: Color
    let kicker: String
    let title: String
    let line: String
    let cta: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(emoji).font(.system(size: 28))
                    Spacer()
                    Text(kicker)
                        .font(.caption2.bold())
                        .foregroundStyle(accent)
                }
                Text(title)
                    .font(Theme.display(17, weight: .bold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                Text(line)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(cta)
                    .font(.caption.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(accent, in: Capsule())
                    .foregroundStyle(.white)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .chunkyCard(accent.opacity(0.10))
        }
        .buttonStyle(.plain)
    }
}

private struct StatusSheet: View {
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var text = "free to hangout"
    @State private var emoji = "🟢"

    private let presets = [
        ("🟢", "free to hangout"),
        ("📚", "grinding, do not disturb"),
        ("😴", "recharging, text tomorrow"),
        ("🍜", "down for food only"),
        ("🫠", "existing horizontally"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ForEach(presets, id: \.1) { preset in
                    Button {
                        emoji = preset.0
                        text = preset.1
                    } label: {
                        HStack {
                            Text(preset.0)
                            Text(preset.1)
                            Spacer()
                            if text == preset.1 {
                                Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(12)
                        .background(text == preset.1 ? Theme.accentSoft : Theme.card,
                                    in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                TextField("or write your own...", text: $text)
                    .padding(12)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                Spacer()
            }
            .padding(20)
            .navigationTitle("what's the vibe?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("set it") {
                        onSave(text, emoji)
                        dismiss()
                    }
                }
            }
        }
    }
}
