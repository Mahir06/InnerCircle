import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: TabRouter
    @StateObject private var vm = HomeViewModel()
    @State private var showStatusSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusBar
                    carousel
                    sparkCard
                }
                .padding(16)
            }
            .navigationTitle("yo, \(appState.currentUser?.displayName ?? "you")")
            .onAppear {
                if let circleId = appState.circle?.id, let uid = appState.authUid {
                    vm.start(circleId: circleId, userId: uid)
                }
            }
            .sheet(isPresented: $showStatusSheet) {
                StatusSheet { text, emoji in
                    vm.setStatus(text: text, emoji: emoji)
                }
                .presentationDetents([.medium])
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
                                .frame(width: 54, height: 54)
                                .background(Theme.colorway(member.idCard.color).opacity(0.25),
                                            in: SwiftUI.Circle())
                            if let status = member.status {
                                Text(status.emoji)
                                    .font(.system(size: 15))
                                    .offset(x: 3, y: 3)
                            }
                        }
                        Text(isMe ? "you" : member.displayName)
                            .font(.caption2.bold())
                        Text(member.status?.text ?? "no status")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 70)
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

    // MARK: carousel

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                hangoutCard
                if let postcard = vm.expiringPostcard {
                    postcardCard(postcard)
                }
                if let poll = vm.activePoll, let question = poll.poll?.question {
                    pollCard(poll, question: question)
                }
                if let sparkDrop = vm.latestSparkDrop, let spark = sparkDrop.spark {
                    sparkResponsesCard(spark)
                }
            }
        }
        .scrollTargetBehavior(.viewAligned)
    }

    @ViewBuilder
    private var hangoutCard: some View {
        if let hangout = vm.nextHangout {
            HomeCard(
                emoji: hangout.poster.emoji,
                accent: Theme.colorway(hangout.poster.colorway),
                kicker: hangout.status == .live ? "happening NOW" : "next up",
                title: hangout.title,
                line: hangout.startsAt.map { $0.formatted(date: .abbreviated, time: .shortened) }
                    ?? "date TBD, classic",
                cta: hangout.status == .live ? "join in" : "RSVP"
            ) { router.selection = "hangouts" }
        } else {
            HomeCard(
                emoji: "🗓️",
                accent: Theme.accent,
                kicker: "the calendar",
                title: Copy.homeEmptyHangout,
                line: "someone has to be the hero",
                cta: "plan something"
            ) { router.selection = "hangouts" }
        }
    }

    private func postcardCard(_ postcard: Postcard) -> some View {
        HomeCard(
            emoji: "✉️",
            accent: .orange,
            kicker: sealCountdown(postcard.sealsAt),
            title: postcard.hangoutTitle ?? "open postcard",
            line: "add your bit before the envelope seals",
            cta: "contribute"
        ) { router.selection = "mailbox" }
    }

    private func pollCard(_ message: Message, question: String) -> some View {
        HomeCard(
            emoji: "📊",
            accent: Theme.colorway("sky"),
            kicker: "\(message.poll?.totalVotes ?? 0) votes in",
            title: question,
            line: "democracy needs you",
            cta: "vote"
        ) { router.selection = "chat" }
    }

    private func sparkResponsesCard(_ spark: SparkDrop) -> some View {
        HomeCard(
            emoji: "✨",
            accent: Theme.colorway("grape"),
            kicker: "\(spark.answers.count) answered",
            title: spark.prompt,
            line: "see what everyone said",
            cta: "peek"
        ) { router.selection = "chat" }
    }

    // MARK: spark of the day

    @ViewBuilder
    private var sparkCard: some View {
        if let spark = vm.todaySpark {
            VStack(alignment: .leading, spacing: 8) {
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
                    .font(.subheadline.bold())
                Button("answer in chat") { router.selection = "chat" }
                    .font(.caption.bold())
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

// MARK: - card + status sheet

private struct HomeCard: View {
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
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(line)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(cta)
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accent, in: Capsule())
                    .foregroundStyle(.white)
            }
            .padding(14)
            .frame(width: 270, height: 150, alignment: .leading)
            .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
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
