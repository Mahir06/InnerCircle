import SwiftUI

// Search public circles and view their profiles. shhh... it stays here.
struct FindCirclesView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: CircleViewModel

    @State private var query = ""
    @State private var results: [FriendCircle] = []
    @State private var searched = false
    @State private var busy = false

    private let circleRepo = CircleRepository()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    TextField("search public circles...", text: $query)
                        .textInputAutocapitalization(.never)
                        .padding(12)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
                        .onSubmit { search() }
                    Button {
                        search()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .padding(12)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                }

                if busy {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                } else if searched && results.isEmpty {
                    VStack(spacing: 8) {
                        Illustration(slot: "mascot-search", size: 120)
                        Text("no circles out there with that name")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }

                ForEach(results) { circle in
                    NavigationLink {
                        PublicCircleProfileView(circle: circle)
                            .environmentObject(vm)
                    } label: {
                        HStack(spacing: 12) {
                            Text(circle.coverEmoji)
                                .font(.system(size: 30))
                                .frame(width: 54, height: 54)
                                .background(Theme.accentSoft, in: SwiftUI.Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(circle.name).font(Theme.cardTitle)
                                if let bio = circle.bio {
                                    Text(bio).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                                Text("\(circle.memberIds.count) members · \(circle.stats.hangoutsCompleted) hangouts")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .chunkyCard()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .navigationTitle("find circles")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func search() {
        busy = true
        Task {
            defer { busy = false }
            let found = (try? await circleRepo.searchPublicCircles(query: query)) ?? []
            results = found.filter { $0.id != appState.circle?.id }
            searched = true
        }
    }
}

// MARK: - public profile

struct PublicCircleProfileView: View {
    let circle: FriendCircle
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: CircleViewModel

    @State private var showcase: [Postcard] = []
    @State private var requestSent = false

    private let circleRepo = CircleRepository()
    private let postcardRepo = PostcardRepository()

    private var relationship: Relationship {
        guard let mine = appState.circle else { return .stranger }
        if (mine.friendCircleIds ?? []).contains(circle.id ?? "") { return .friends }
        if (mine.sentFriendRequests ?? []).contains(circle.id ?? "") || requestSent { return .pending }
        return .stranger
    }

    enum Relationship { case stranger, pending, friends }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(circle.coverEmoji).font(.system(size: 56))
                    Text(circle.name)
                        .font(Theme.display(28, weight: .black))
                        .foregroundStyle(.white)
                    if let bio = circle.bio {
                        Text(bio)
                            .font(Theme.displayItalic(14))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    Text("\(circle.memberIds.count) members")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .background(
                    LinearGradient(colors: [Theme.accent, Theme.accentDeep],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 26)
                )

                HStack(spacing: 12) {
                    statBox("🎉", "\(circle.stats.hangoutsCompleted)", "hangouts")
                    statBox("🍽️", "\(circle.stats.restaurantsVisited)", "restaurants")
                    statBox("📍", "\(circle.stats.placesVisited)", "places")
                }

                switch relationship {
                case .friends:
                    Label("circle friends", systemImage: "checkmark.seal.fill")
                        .font(Theme.cardTitle)
                        .foregroundStyle(Theme.accent)
                case .pending:
                    Label("request sent. they're deliberating", systemImage: "hourglass")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                case .stranger:
                    Button("add as circle friends 🤝") { sendRequest() }
                        .buttonStyle(ChunkyButtonStyle())
                }

                if !showcase.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("their showcase").font(Theme.heading)
                        ForEach(showcase) { postcard in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(postcard.hangoutTitle ?? "a memory")
                                    .font(Theme.cardTitle)
                                Text(postcard.createdAt.formatted(date: .long, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                ForEach(postcard.blocks.filter { $0.type == .text || $0.type == .aiSummary }.prefix(2)) { block in
                                    Text("\"\(block.content)\"")
                                        .font(Theme.displayItalic(13))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .chunkyCard(Theme.paper)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle(circle.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadShowcase() }
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

    private func loadShowcase() {
        guard let circleId = circle.id, let ids = circle.showcasePostcardIds, !ids.isEmpty else { return }
        Task {
            showcase = (try? await postcardRepo.fetchShowcase(ids: ids, circleId: circleId)) ?? []
        }
    }

    private func sendRequest() {
        guard let mine = appState.circle, let targetId = circle.id, let uid = appState.authUid else { return }
        requestSent = true
        Task {
            try? await circleRepo.sendFriendRequest(from: mine, to: targetId, sentBy: uid)
        }
    }
}
