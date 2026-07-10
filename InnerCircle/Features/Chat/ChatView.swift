import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ChatViewModel()

    var body: some View {
        NavigationStack {
            ChatSurface(vm: vm)
                .navigationTitle(Copy.chatTitle)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    if let circleId = appState.circle?.id, let uid = appState.authUid {
                        vm.start(circleId: circleId, userId: uid)
                    }
                }
        }
        .environmentObject(vm)
    }
}

// The message list + input bar, shared by the circle chat and each
// hangout's chat. The parent owns the view model and starts it.
struct ChatSurface: View {
    @ObservedObject var vm: ChatViewModel
    @EnvironmentObject var appState: AppState
    @State private var draft = ""
    @State private var showPollComposer = false
    @State private var openSession: GameShelfView.SessionRef?

    var body: some View {
            VStack(spacing: 0) {
                if vm.drops.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Illustration(slot: "empty-chat")
                        Text(Copy.chatEmpty)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(vm.drops) { drop in
                                    DropBubble(message: drop)
                                        .id(drop.id)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .onChange(of: vm.drops.count) { _, _ in
                            if let last = vm.drops.last?.id {
                                withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                            }
                        }
                        .onAppear {
                            if let last = vm.drops.last?.id {
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                inputBar
            }
            .sheet(isPresented: $showPollComposer) {
                PollComposerSheet { question, options, multi in
                    vm.sendPoll(question: question, options: options, allowsMultiple: multi)
                }
            }
            .sheet(item: $openSession) { ref in
                NavigationStack {
                    GameSessionView(sessionId: ref.id)
                }
            }
            .environmentObject(vm)   // the bubbles read the vm from the environment
    }

    private func openTable(_ game: OnlineGame) {
        let userId = vm.userId
        let circleId = vm.circleId
        Task {
            if let id = try? await GameSessionViewModel.openTable(game: game, hostId: userId, circleId: circleId) {
                openSession = GameShelfView.SessionRef(id: id)
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            Menu {
                Button {
                    showPollComposer = true
                } label: {
                    Label("start a poll", systemImage: "chart.bar.fill")
                }
                Button {
                    vm.dropSpark()
                } label: {
                    Label("drop a spark", systemImage: "sparkles")
                }
                Menu {
                    ForEach(OnlineGame.playable) { game in
                        Button("\(game.emoji) \(game.title)") {
                            openTable(game)
                        }
                    }
                } label: {
                    Label("open a game table", systemImage: "gamecontroller.fill")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent)
            }

            TextField("say something...", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))

            Button {
                vm.sendText(draft)
                draft = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : Theme.accent)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - Bubbles

private struct DropBubble: View {
    let message: Message
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: ChatViewModel

    private var isMine: Bool { message.senderId == appState.authUid }

    var body: some View {
        switch message.type {
        case .system:
            Text(message.text ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
        case .text:
            bubbleRow {
                Text(message.text ?? "")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        isMine ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.card),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .foregroundStyle(isMine ? .white : .primary)
            }
        case .poll:
            bubbleRow { PollBubble(message: message) }
        case .spark:
            bubbleRow { SparkBubble(message: message) }
        case .hangoutInvite:
            bubbleRow { HangoutInviteBubble(message: message) }
        case .gameInvite:
            bubbleRow { GameInviteBubble(message: message) }
        }
    }

    @ViewBuilder
    private func bubbleRow(@ViewBuilder content: () -> some View) -> some View {
        HStack {
            if isMine { Spacer(minLength: 48) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 3) {
                if !isMine {
                    Text(appState.memberName(message.senderId))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .padding(.leading, 6)
                }
                content()
                    .contextMenu { contextActions }
                reactionChips
            }
            if !isMine { Spacer(minLength: 48) }
        }
    }

    @ViewBuilder
    private var contextActions: some View {
        ForEach(["😂", "❤️", "🔥", "💀", "👍"], id: \.self) { emoji in
            Button {
                vm.toggleReaction(message: message, emoji: emoji)
            } label: {
                Text(emoji)
            }
        }
        if message.type == .text, !isMine {
            Button {
                vm.saveQuote(message: message)
            } label: {
                Label("frame this quote", systemImage: "quote.opening")
            }
        }
    }

    @ViewBuilder
    private var reactionChips: some View {
        let reactions = (message.reactions ?? [:]).filter { !$0.value.isEmpty }
        if !reactions.isEmpty {
            HStack(spacing: 4) {
                ForEach(reactions.keys.sorted(), id: \.self) { emoji in
                    let count = reactions[emoji]?.count ?? 0
                    Text(count > 1 ? "\(emoji) \(count)" : emoji)
                        .font(.caption)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.card, in: Capsule())
                        .onTapGesture {
                            vm.toggleReaction(message: message, emoji: emoji)
                        }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

private struct PollBubble: View {
    let message: Message
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: ChatViewModel

    var body: some View {
        if let poll = message.poll {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(Theme.accent)
                    Text(poll.question).font(.subheadline.bold())
                }
                if poll.allowsMultipleAnswers {
                    Text("pick as many as you want")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ForEach(poll.options) { option in
                    let voted = option.voterIds.contains(appState.authUid ?? "")
                    Button {
                        vm.vote(message: message, optionId: option.id)
                    } label: {
                        HStack {
                            Image(systemName: voted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(voted ? Theme.accent : .secondary)
                            Text(option.label)
                            Spacer()
                            Text("\(option.voterIds.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(voted ? Theme.accentSoft : Theme.card.opacity(0.6),
                                    in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                Text("\(poll.totalVotes) vote\(poll.totalVotes == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: 300, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

private struct SparkBubble: View {
    let message: Message
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: ChatViewModel
    @State private var answer = ""

    var body: some View {
        if let spark = message.spark {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("spark").font(.caption.bold()).foregroundStyle(.secondary)
                }
                Text(spark.prompt).font(.subheadline.bold())

                let myAnswer = spark.answers[appState.authUid ?? ""]
                if myAnswer == nil {
                    HStack {
                        TextField("your answer...", text: $answer)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Theme.card.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                        Button("go") {
                            vm.answerSpark(message: message, answer: answer)
                            answer = ""
                        }
                        .font(.caption.bold())
                        .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                ForEach(spark.answers.keys.sorted(), id: \.self) { userId in
                    HStack(alignment: .top, spacing: 6) {
                        Text(appState.memberName(userId))
                            .font(.caption.bold())
                        Text(spark.answers[userId] ?? "")
                            .font(.caption)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: 300, alignment: .leading)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

private struct HangoutInviteBubble: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "party.popper.fill")
                    .foregroundStyle(Theme.accent)
                Text("hangout invite").font(.caption.bold()).foregroundStyle(.secondary)
            }
            Text(message.text ?? "a mystery plan")
                .font(.subheadline.bold())
            Text("RSVP on the Hangouts tab")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: 280, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.accent.opacity(0.4), lineWidth: 1.5))
    }
}

private struct GameInviteBubble: View {
    let message: Message
    @State private var showTable = false

    var body: some View {
        Button {
            showTable = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundStyle(Theme.accent)
                    Text("game invite").font(.caption.bold()).foregroundStyle(.secondary)
                }
                Text(message.text ?? "a mystery game")
                    .font(.subheadline.bold())
                Text("tap to join the table")
                    .font(.caption2)
                    .foregroundStyle(Theme.accent)
            }
            .padding(12)
            .frame(maxWidth: 280, alignment: .leading)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showTable) {
            if let sessionId = message.gameSessionId {
                NavigationStack {
                    GameSessionView(sessionId: sessionId)
                }
            }
        }
    }
}

// MARK: - Poll composer

private struct PollComposerSheet: View {
    let onCreate: (String, [String], Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var question = ""
    @State private var options = ["", ""]
    @State private var allowsMultiple = false

    var body: some View {
        NavigationStack {
            Form {
                Section("the big question") {
                    TextField("settle it once and for all...", text: $question)
                }
                Section("options") {
                    ForEach(options.indices, id: \.self) { i in
                        TextField("option \(i + 1)", text: $options[i])
                    }
                    if options.count < 5 {
                        Button {
                            options.append("")
                        } label: {
                            Label("add option", systemImage: "plus")
                        }
                    }
                }
                Section {
                    Toggle("allow multiple answers", isOn: $allowsMultiple)
                }
            }
            .navigationTitle("start a poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("drop it") {
                        onCreate(
                            question.trimmingCharacters(in: .whitespaces),
                            options.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
                            allowsMultiple
                        )
                        dismiss()
                    }
                    .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty ||
                              options.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count < 2)
                }
            }
        }
    }
}
