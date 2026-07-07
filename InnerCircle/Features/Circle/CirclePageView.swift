import SwiftUI

struct CirclePageView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = CircleViewModel()
    @State private var showEditSheet = false
    @State private var newBucketItem = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                if let circle = appState.circle {
                    VStack(alignment: .leading, spacing: 18) {
                        banner(circle)
                        ticketCard(circle)
                        statsRow(circle)
                        membersSection
                        stampsSection
                        bucketListSection(circle)
                        signOut
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Circle")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let circleId = appState.circle?.id, let uid = appState.authUid {
                    vm.start(circleId: circleId, userId: uid)
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let circle = appState.circle {
                    EditCircleSheet(circle: circle) { name, emoji in
                        vm.updateCircleProfile(name: name, coverEmoji: emoji, circleId: circle.id ?? "")
                    }
                    .presentationDetents([.medium])
                }
            }
        }
    }

    // MARK: banner

    private func banner(_ circle: FriendCircle) -> some View {
        VStack(spacing: 8) {
            Text(circle.coverEmoji).font(.system(size: 56))
            Text(circle.name)
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("\(circle.memberIds.count)/\(FriendCircle.maxMembers) members strong")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
            Button("edit") { showEditSheet = true }
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: group ticket

    private func ticketCard(_ circle: FriendCircle) -> some View {
        VStack(spacing: 8) {
            Text("🎟️ Group Ticket").font(.headline)
            Text(circle.code)
                .font(.system(size: 34, weight: .heavy, design: .monospaced))
                .kerning(5)
            ShareLink(item: "you're invited to \(circle.name) on Inner Circle 🎟️ your Group Ticket: \(circle.code)") {
                Label("invite your people", systemImage: "square.and.arrow.up")
                    .font(.caption.bold())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: stats

    private func statsRow(_ circle: FriendCircle) -> some View {
        HStack(spacing: 12) {
            statBox("🎉", "\(circle.stats.hangoutsCompleted)", "hangouts")
            statBox("🍽️", "\(circle.stats.restaurantsVisited)", "restaurants")
            statBox("📍", "\(circle.stats.placesVisited)", "places")
        }
    }

    private func statBox(_ emoji: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(emoji).font(.title3)
            Text(value).font(.title2.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: members

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("the circle").font(.headline)
            ForEach(appState.members) { member in
                HStack(spacing: 12) {
                    Text(member.idCard.emoji)
                        .font(.system(size: 26))
                        .frame(width: 46, height: 46)
                        .background(Theme.colorway(member.idCard.color).opacity(0.25),
                                    in: SwiftUI.Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.displayName).font(.subheadline.bold())
                        Text(member.idCard.tagline)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let status = member.status {
                        Text(status.emoji)
                    }
                }
                .padding(10)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: stamps

    private var stampsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("stamps").font(.headline)
            StampsGrid(stamps: vm.stamps)
        }
    }

    // MARK: bucket list

    private func bucketListSection(_ circle: FriendCircle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🪣 bucket list").font(.headline)
            if circle.bucketList.isEmpty {
                Text("no dreams yet? tragic. add one")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(circle.bucketList) { item in
                Button {
                    vm.toggleBucketListItem(item.id, circle: circle)
                } label: {
                    HStack {
                        Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.done ? Theme.accent : .secondary)
                        Text(item.label)
                            .strikethrough(item.done)
                        Spacer()
                        if item.done {
                            Text("done ✨").font(.caption2).foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            HStack {
                TextField("add a dream", text: $newBucketItem)
                    .font(.footnote)
                Button("add") {
                    vm.addBucketListItem(newBucketItem, circle: circle)
                    newBucketItem = ""
                }
                .font(.caption.bold())
                .disabled(newBucketItem.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private var signOut: some View {
        Button("sign out") { appState.signOut() }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}

// MARK: - edit sheet

private struct EditCircleSheet: View {
    let circle: FriendCircle
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String

    private let emojiChoices = ["🌀", "🔥", "🌈", "🛸", "🍜", "🏝️", "🎪", "⚡️", "🐙", "🎮", "🧿", "🚀"]

    init(circle: FriendCircle, onSave: @escaping (String, String) -> Void) {
        self.circle = circle
        self.onSave = onSave
        _name = State(initialValue: circle.name)
        _emoji = State(initialValue: circle.coverEmoji)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("circle name", text: $name)
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(emojiChoices, id: \.self) { choice in
                        Text(choice)
                            .font(.system(size: 30))
                            .padding(6)
                            .background(choice == emoji ? Theme.accentSoft : .clear,
                                        in: RoundedRectangle(cornerRadius: 10))
                            .onTapGesture { emoji = choice }
                    }
                }
                Spacer()
            }
            .padding(20)
            .navigationTitle("circle makeover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        onSave(name.trimmingCharacters(in: .whitespaces), emoji)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
