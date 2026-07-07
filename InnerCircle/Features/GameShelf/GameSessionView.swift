import SwiftUI

// One screen for every online game: lobby -> rounds -> scoreboard.
struct GameSessionView: View {
    let sessionId: String
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = GameSessionViewModel()

    var body: some View {
        Group {
            if let session = vm.session {
                let game = OnlineGame.byId(session.gameId)
                ScrollView {
                    VStack(spacing: 16) {
                        header(session, game: game)
                        switch session.state {
                        case .lobby: LobbyView(session: session, game: game, vm: vm)
                        case .active: activeView(session)
                        case .done: DoneView(session: session, vm: vm)
                        }
                        if let error = vm.errorMessage {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    .padding(16)
                }
            } else {
                ProgressView("finding the table...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(OnlineGame.byId(vm.session?.gameId ?? "")?.title ?? "game on")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let circleId = appState.circle?.id, let uid = appState.authUid {
                vm.start(sessionId: sessionId, circleId: circleId, userId: uid)
            }
        }
    }

    private func header(_ session: GameSession, game: OnlineGame?) -> some View {
        VStack(spacing: 6) {
            Text(game?.emoji ?? "🎮").font(.system(size: 44))
            Text(game?.tagline ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if session.state == .active && session.gameId != "theSnake" {
                Text("round \(session.round + 1) of \(session.totalRounds)")
                    .font(.caption2.bold())
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func activeView(_ session: GameSession) -> some View {
        switch session.gameId {
        case "mostLikelyTo": MostLikelyToView(session: session, vm: vm)
        case "hotTakes": HotTakesView(session: session, vm: vm)
        case "fibber": FibberView(session: session, vm: vm)
        case "theSnake": SnakeView(session: session, vm: vm)
        default: Text("this game escaped the shelf").foregroundStyle(.secondary)
        }
    }
}

// MARK: - lobby

private struct LobbyView: View {
    let session: GameSession
    let game: OnlineGame?
    @ObservedObject var vm: GameSessionViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            Text("the table is set").font(.headline)
            ForEach(session.players, id: \.self) { player in
                HStack {
                    Text(appState.member(player)?.idCard.emoji ?? "🙂")
                    Text(appState.memberName(player))
                    if player == session.hostId {
                        Text("host").font(.caption2.bold()).foregroundStyle(Theme.accent)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
                .padding(10)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
            }

            let needed = max(0, (game?.minPlayers ?? 2) - session.players.count)
            if needed > 0 {
                Text("need \(needed) more player\(needed == 1 ? "" : "s"). shame someone in chat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !vm.iAmIn {
                bigButton("pull up a chair") { vm.join() }
            } else if vm.isHost {
                bigButton("start the game") { vm.startGame() }
                    .disabled(needed > 0)
                    .opacity(needed > 0 ? 0.5 : 1)
            } else {
                Text("waiting for \(appState.memberName(session.hostId)) to start...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Most Likely To

private struct MostLikelyToView: View {
    let session: GameSession
    @ObservedObject var vm: GameSessionViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            Text(session.currentPrompt ?? "most likely to break the app")
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            if vm.allInputsIn {
                RevealBars(
                    counts: Dictionary(grouping: session.votes.values, by: { $0 }).mapValues(\.count),
                    label: { appState.memberName($0) }
                )
                ScoreStrip(scores: session.scores)
                HostNextButton(vm: vm, label: session.round + 1 >= session.totalRounds ? "final scores" : "next round")
            } else if vm.myVote == nil {
                Text("point the finger").font(.caption).foregroundStyle(.secondary)
                ForEach(session.players, id: \.self) { player in
                    Button {
                        vm.vote(player)
                    } label: {
                        HStack {
                            Text(appState.member(player)?.idCard.emoji ?? "🙂")
                            Text(appState.memberName(player))
                            Spacer()
                        }
                        .padding(12)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                WaitingView(have: session.votes.count, need: session.players.count)
            }
        }
    }
}

// MARK: - Hot Takes

private struct HotTakesView: View {
    let session: GameSession
    @ObservedObject var vm: GameSessionViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            Text(session.currentPrompt ?? "hot take: this app is great")
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            if vm.allInputsIn {
                let agree = session.submissions.filter { $0.value == "agree" }.keys.map { appState.memberName($0) }
                let disagree = session.submissions.filter { $0.value == "disagree" }.keys.map { appState.memberName($0) }
                HStack(alignment: .top, spacing: 12) {
                    sideColumn("💯 agree", names: agree)
                    sideColumn("🚫 disagree", names: disagree)
                }
                let minority = agree.count < disagree.count ? agree : (disagree.count < agree.count ? disagree : [])
                if minority.isEmpty {
                    Text("dead even. nobody defends, everybody argues")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("\(minority.joined(separator: ", ")): defend yourselves in chat 🎤")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.accent)
                }
                HostNextButton(vm: vm, label: session.round + 1 >= session.totalRounds ? "that's the game" : "next take")
            } else if vm.mySubmission == nil {
                HStack(spacing: 12) {
                    bigChoice("💯", "agree") { vm.submit("agree") }
                    bigChoice("🚫", "disagree") { vm.submit("disagree") }
                }
                Text("lock it in. no fence sitting")
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                WaitingView(have: session.submissions.count, need: session.players.count)
            }
        }
    }

    private func sideColumn(_ title: String, names: [String]) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.caption.bold())
            ForEach(names, id: \.self) { Text($0).font(.footnote) }
            if names.isEmpty { Text("nobody").font(.footnote).foregroundStyle(.tertiary) }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
    }

    private func bigChoice(_ emoji: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 34))
                Text(label).font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Fibber

private struct FibberView: View {
    let session: GameSession
    @ObservedObject var vm: GameSessionViewModel
    @EnvironmentObject var appState: AppState
    @State private var answer = ""

    private var subject: String { vm.fibberSubject ?? "" }
    private var iAmSubject: Bool { subject == vm.userId }
    private var prompt: String {
        (session.currentPrompt ?? "what is {name}'s deal?")
            .replacingOccurrences(of: "{name}", with: appState.memberName(subject))
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(prompt).font(.title3.bold()).multilineTextAlignment(.center)

            switch session.phase {
            case "write":
                if vm.mySubmission == nil {
                    Text(iAmSubject ? "you're the subject. write the REAL answer" : "write a convincing lie")
                        .font(.caption.bold())
                        .foregroundStyle(iAmSubject ? Theme.accent : .secondary)
                    HStack {
                        TextField(iAmSubject ? "the truth..." : "your fib...", text: $answer)
                            .padding(10)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                        Button("lock") {
                            vm.submit(answer)
                            answer = ""
                        }
                        .font(.caption.bold())
                        .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } else {
                    WaitingView(have: session.submissions.count, need: session.players.count)
                }
                if vm.allInputsIn && vm.isHost {
                    bigButton("answers are in. open voting") { vm.openFibberVoting() }
                }
            case "vote":
                if iAmSubject {
                    Text("sit back. watch them guess your life")
                        .font(.caption).foregroundStyle(.secondary)
                } else if vm.myVote == nil {
                    Text("which one is \(appState.memberName(subject))'s real answer?")
                        .font(.caption).foregroundStyle(.secondary)
                    // shuffle deterministically by content so everyone sees the same order
                    ForEach(session.submissions.sorted(by: { $0.value < $1.value }), id: \.key) { owner, text in
                        if owner != vm.userId {
                            Button {
                                vm.vote(owner)
                            } label: {
                                Text(text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if vm.allInputsIn {
                    VStack(spacing: 8) {
                        Text("the truth was: \"\(session.submissions[subject] ?? "?")\"")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.accent)
                        ForEach(session.votes.sorted(by: { $0.key < $1.key }), id: \.key) { voter, chosen in
                            Text("\(appState.memberName(voter)) fell for \(chosen == subject ? "the TRUTH ✅" : appState.memberName(chosen) + "'s fib 🤥")")
                                .font(.caption)
                        }
                        ScoreStrip(scores: session.scores)
                        HostNextButton(vm: vm, label: session.round + 1 >= session.totalRounds ? "final scores" : "next victim")
                    }
                } else if vm.myVote != nil {
                    WaitingView(have: session.votes.count, need: session.players.count - 1)
                }
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - The Snake

private struct SnakeView: View {
    let session: GameSession
    @ObservedObject var vm: GameSessionViewModel
    @EnvironmentObject var appState: AppState
    @State private var picks: Set<String> = []

    private var squadSize: Int { min(2 + session.round / 2, max(2, session.players.count - 1)) }
    private var iAmCaptain: Bool { vm.snakeCaptain == vm.userId }
    private var iAmOnSquad: Bool { vm.snakeSquad.contains(vm.userId) }

    var body: some View {
        VStack(spacing: 14) {
            // your secret role, eyes only
            HStack {
                Text(vm.myRole == "snake" ? "🐍" : "🛡️")
                Text(vm.myRole == "snake"
                     ? "you are a Snake. sabotage quietly. deny everything"
                     : "you are Loyal. find the snakes before they ruin everything")
                    .font(.caption.bold())
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(vm.myRole == "snake" ? Color.red.opacity(0.12) : Color.green.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 16) {
                Label("\(session.board["wins"] ?? "0") passed", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                Label("\(session.board["fails"] ?? "0") sabotaged", systemImage: "xmark.shield.fill")
                    .foregroundStyle(.red)
            }
            .font(.caption.bold())

            if let last = session.board["lastMission"], !last.isEmpty {
                Text(last == "fail"
                     ? "mission failed. a snake was on that squad 🫢"
                     : "mission passed. either no snakes went, or they're playing the long game")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("mission: \(session.currentPrompt ?? "guard the vault")")
                .font(.subheadline.bold())

            switch session.phase {
            case "squad":
                if iAmCaptain {
                    Text("you're captain. pick \(squadSize) for the mission")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.accent)
                    ForEach(session.players, id: \.self) { player in
                        Button {
                            if picks.contains(player) {
                                picks.remove(player)
                            } else if picks.count < squadSize {
                                picks.insert(player)
                            }
                        } label: {
                            HStack {
                                Image(systemName: picks.contains(player) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(picks.contains(player) ? Theme.accent : .secondary)
                                Text(appState.memberName(player))
                                Spacer()
                            }
                            .padding(10)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    bigButton("send the squad") { vm.lockSquad(Array(picks)) }
                        .disabled(picks.count != squadSize)
                        .opacity(picks.count == squadSize ? 1 : 0.5)
                } else {
                    Text("\(appState.memberName(vm.snakeCaptain ?? "")) is picking the squad. look trustworthy")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            case "mission":
                let squadNames = vm.snakeSquad.map { appState.memberName($0) }.joined(separator: ", ")
                Text("squad: \(squadNames)").font(.caption)
                if iAmOnSquad && session.submissions[vm.userId] == nil {
                    Text("your move, agent").font(.caption.bold())
                    HStack(spacing: 12) {
                        bigButton("succeed ✅") { vm.submit("success") }
                        if vm.myRole == "snake" {
                            Button {
                                vm.submit("sabotage")
                            } label: {
                                Text("sabotage 🐍")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                } else {
                    WaitingView(have: session.submissions.count, need: vm.snakeSquad.count)
                }
                if vm.allInputsIn && vm.isHost {
                    bigButton("reveal the mission result") { vm.nextRound() }
                }
            default:
                EmptyView()
            }
        }
        .onChange(of: session.round) { _, _ in picks = [] }
    }
}

// MARK: - done

private struct DoneView: View {
    let session: GameSession
    @ObservedObject var vm: GameSessionViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            if session.gameId == "theSnake" {
                let winner = session.board["winner"] ?? "loyals"
                Text(winner == "snakes" ? "🐍" : "🛡️").font(.system(size: 56))
                Text(winner == "snakes"
                     ? "the snakes win. betrayal tastes delicious"
                     : "the loyals win. the snakes slither back into the group chat")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 4) {
                    Text("the snakes were:").font(.caption.bold())
                    ForEach(session.players.filter { session.board["role_\($0)"] == "snake" }, id: \.self) { snake in
                        Text("🐍 \(appState.memberName(snake))").font(.footnote)
                    }
                }
            } else {
                Text("🏁 final scores").font(.headline)
                let ranked = session.scores.sorted { $0.value > $1.value }
                ForEach(Array(ranked.enumerated()), id: \.element.key) { index, entry in
                    HStack {
                        Text(index == 0 ? "👑" : "\(index + 1).")
                        Text(appState.memberName(entry.key))
                        Spacer()
                        Text("\(entry.value)").font(.headline)
                    }
                    .padding(10)
                    .background(index == 0 ? Theme.accentSoft : Theme.card,
                                in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

// MARK: - shared bits

private struct WaitingView: View {
    let have: Int
    let need: Int

    var body: some View {
        VStack(spacing: 6) {
            ProgressView(value: Double(have), total: Double(max(need, 1)))
            Text("\(have)/\(need) locked in. peer pressure the rest")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

private struct RevealBars: View {
    let counts: [String: Int]
    let label: (String) -> String

    var body: some View {
        let total = max(counts.values.reduce(0, +), 1)
        VStack(spacing: 8) {
            ForEach(counts.sorted { $0.value > $1.value }, id: \.key) { target, count in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(label(target)).font(.caption.bold())
                        Spacer()
                        Text("\(count)").font(.caption)
                    }
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * CGFloat(count) / CGFloat(total))
                    }
                    .frame(height: 8)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
}

private struct ScoreStrip: View {
    let scores: [String: Int]
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 10) {
            ForEach(scores.sorted { $0.value > $1.value }, id: \.key) { uid, score in
                Text("\(appState.memberName(uid)) \(score)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.card, in: Capsule())
            }
        }
    }
}

private struct HostNextButton: View {
    @ObservedObject var vm: GameSessionViewModel
    let label: String
    @EnvironmentObject var appState: AppState

    var body: some View {
        if vm.isHost {
            bigButton(label) { vm.nextRound() }
        } else if let host = vm.session?.hostId {
            Text("\(appState.memberName(host)) has the remote...")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

@MainActor
func bigButton(_ label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
    }
}
