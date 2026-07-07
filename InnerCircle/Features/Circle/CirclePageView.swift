import SwiftUI

struct CirclePageView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = CircleViewModel()
    @State private var showEditSheet = false
    @State private var showShowcasePicker = false
    @State private var newBucketItem = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                if let circle = appState.circle {
                    VStack(alignment: .leading, spacing: 18) {
                        banner(circle)
                        heatMapSection
                        ticketCard(circle)
                        statsRow(circle)
                        requestsSection
                        membersSection
                        friendsSection(circle)
                        stampsSection
                        quotesSection(circle)
                        bucketListSection(circle)
                        signOut
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        FindCirclesView()
                            .environmentObject(vm)
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .onAppear {
                if let circleId = appState.circle?.id, let uid = appState.authUid {
                    vm.start(circleId: circleId, userId: uid)
                }
                if let circle = appState.circle {
                    vm.loadFriends(circle)
                    vm.syncSentRequests(circle)
                }
            }
            .onChange(of: appState.circle?.friendCircleIds) { _, _ in
                if let circle = appState.circle { vm.loadFriends(circle) }
            }
            .sheet(isPresented: $showEditSheet) {
                if let circle = appState.circle {
                    EditCircleSheet(circle: circle) { name, emoji, bio, isPublic in
                        vm.updateCircleProfile(name: name, coverEmoji: emoji, bio: bio, isPublic: isPublic, circleId: circle.id ?? "")
                    }
                }
            }
            .sheet(isPresented: $showShowcasePicker) {
                ShowcasePickerSheet(selected: appState.circle?.showcasePostcardIds ?? []) { ids in
                    vm.updateShowcase(postcardIds: ids)
                }
                .environmentObject(appState)
            }
        }
    }

    // MARK: banner

    private func banner(_ circle: FriendCircle) -> some View {
        VStack(spacing: 8) {
            Text(circle.coverEmoji).font(.system(size: 56))
            Text(circle.name)
                .font(Theme.display(30, weight: .black))
                .foregroundStyle(.white)
            if let bio = circle.bio, !bio.isEmpty {
                Text(bio)
                    .font(Theme.displayItalic(14))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            HStack(spacing: 10) {
                Text("\(circle.memberIds.count)/\(FriendCircle.maxMembers) members")
                if circle.isDiscoverable {
                    Label("public", systemImage: "eye")
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.85))
            HStack(spacing: 18) {
                Button("edit") { showEditSheet = true }
                Button("showcase") { showShowcasePicker = true }
            }
            .font(.caption.bold())
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(
            LinearGradient(colors: [Theme.accent, Theme.accentDeep],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 26)
        )
        .shadow(color: Theme.accent.opacity(0.35), radius: 12, y: 5)
    }

    // MARK: heat map

    private var heatMapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("the pulse").font(Theme.heading)
            ActivityHeatMap(dates: vm.activityDates)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .chunkyCard()
    }

    // MARK: group ticket

    private func ticketCard(_ circle: FriendCircle) -> some View {
        VStack(spacing: 8) {
            Text("🎟️ Group Ticket").font(Theme.cardTitle)
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
        .chunkyCard(Theme.accentSoft)
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
            Text(value).font(Theme.display(22, weight: .black))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .chunkyCard()
    }

    // MARK: friend requests

    @ViewBuilder
    private var requestsSection: some View {
        if !vm.incomingRequests.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("knock knock").font(Theme.heading)
                ForEach(vm.incomingRequests) { request in
                    HStack(spacing: 12) {
                        Text(request.fromCircleEmoji).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.fromCircleName).font(Theme.cardTitle)
                            Text("wants to be circle friends")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("accept") { vm.acceptRequest(request) }
                            .font(.caption.bold())
                            .buttonStyle(.borderedProminent)
                        Button {
                            vm.declineRequest(request)
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .font(.caption)
                    }
                    .padding(12)
                    .chunkyCard(Theme.accentSoft)
                }
            }
        }
    }

    // MARK: members

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("the circle").font(Theme.heading)
            ForEach(appState.members) { member in
                NavigationLink {
                    IDCardView(member: member, stamps: vm.stamps(for: member.id ?? ""),
                               circleName: appState.circle?.name ?? "")
                } label: {
                    HStack(spacing: 12) {
                        Text(member.idCard.emoji)
                            .font(.system(size: 26))
                            .frame(width: 46, height: 46)
                            .background(Theme.colorway(member.idCard.color).opacity(0.25),
                                        in: SwiftUI.Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.displayName).font(Theme.cardTitle)
                            Text(member.idCard.tagline)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let status = member.status {
                            Text(status.emoji)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .chunkyCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: circle friends

    @ViewBuilder
    private func friendsSection(_ circle: FriendCircle) -> some View {
        if !vm.friendCircles.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("friend circles").font(Theme.heading)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.friendCircles) { friend in
                            NavigationLink {
                                PublicCircleProfileView(circle: friend)
                                    .environmentObject(vm)
                            } label: {
                                VStack(spacing: 4) {
                                    Text(friend.coverEmoji).font(.system(size: 30))
                                    Text(friend.name)
                                        .font(.caption.bold())
                                        .lineLimit(1)
                                }
                                .frame(width: 96)
                                .padding(.vertical, 12)
                                .chunkyCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: stamps

    private var stampsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("stamps").font(Theme.heading)
            StampsGrid(stamps: vm.stamps)
        }
    }

    // MARK: hall of fame quotes

    @ViewBuilder
    private func quotesSection(_ circle: FriendCircle) -> some View {
        if !circle.quotesArchive.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("🗣️ hall of fame").font(Theme.heading)
                ForEach(circle.quotesArchive.sorted { $0.at > $1.at }) { quote in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\u{201C}\(quote.text)\u{201D}")
                            .font(Theme.displayItalic(15))
                        Text("- \(appState.memberName(quote.authorId)), framed by \(appState.memberName(quote.savedBy))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .chunkyCard(Theme.paper)
                }
            }
        }
    }

    // MARK: bucket list

    private func bucketListSection(_ circle: FriendCircle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🪣 bucket list").font(Theme.heading)
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
        .chunkyCard()
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
    let onSave: (String, String, String?, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var bio: String
    @State private var isPublic: Bool

    private let emojiChoices = ["🌀", "🔥", "🌈", "🛸", "🍜", "🏝️", "🎪", "⚡️", "🐙", "🎮", "🧿", "🚀"]

    init(circle: FriendCircle, onSave: @escaping (String, String, String?, Bool) -> Void) {
        self.circle = circle
        self.onSave = onSave
        _name = State(initialValue: circle.name)
        _emoji = State(initialValue: circle.coverEmoji)
        _bio = State(initialValue: circle.bio ?? "")
        _isPublic = State(initialValue: circle.isDiscoverable)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("identity") {
                    TextField("circle name", text: $name)
                    TextField("bio (the vibe in one line)", text: $bio)
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
                }
                Section {
                    Toggle("public circle", isOn: $isPublic)
                } footer: {
                    Text("public circles show up in search with their bio, stats, and showcase postcards. chats and everything else stay private")
                }
            }
            .navigationTitle("circle makeover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        onSave(name.trimmingCharacters(in: .whitespaces), emoji,
                               bio.isEmpty ? nil : bio, isPublic)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - showcase picker

private struct ShowcasePickerSheet: View {
    let selected: [String]
    let onSave: ([String]) -> Void
    @EnvironmentObject var appState: AppState
    @StateObject private var mailbox = MailboxViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var picks: [String] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("pick up to 3 sealed postcards for the public profile")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(mailbox.postcards.filter { $0.isSealed && !$0.isLockedCapsule }) { postcard in
                    Button {
                        guard let id = postcard.id else { return }
                        if picks.contains(id) {
                            picks.removeAll { $0 == id }
                        } else if picks.count < 3 {
                            picks.append(id)
                        }
                    } label: {
                        HStack {
                            Image(systemName: picks.contains(postcard.id ?? "") ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(picks.contains(postcard.id ?? "") ? Theme.accent : .secondary)
                            Text(postcard.hangoutTitle ?? "untitled memory")
                            Spacer()
                            Text(postcard.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("showcase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        onSave(picks)
                        dismiss()
                    }
                }
            }
            .onAppear {
                picks = selected
                if let circleId = appState.circle?.id, let uid = appState.authUid {
                    mailbox.start(circleId: circleId, userId: uid)
                }
            }
        }
    }
}
