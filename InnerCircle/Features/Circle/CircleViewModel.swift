import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class CircleViewModel: ObservableObject {
    @Published var stamps: [Stamp] = []
    @Published var activityDates: [Date] = []           // heat map fuel
    @Published var incomingRequests: [CircleFriendRequest] = []
    @Published var friendCircles: [FriendCircle] = []
    @Published var errorMessage: String?

    private let stampRepo = StampRepository()
    private let circleRepo = CircleRepository()
    private let hangoutRepo = HangoutRepository()
    private let postcardRepo = PostcardRepository()
    private var listeners: [ListenerRegistration] = []
    private var hangoutDates: [Date] = []
    private var postcardDates: [Date] = []
    private var loadedFriendIds: [String] = []
    private(set) var circleId = ""
    private(set) var userId = ""

    func start(circleId: String, userId: String) {
        guard self.circleId != circleId || (listeners.isEmpty && !DemoContent.isActive) else { return }
        stop()
        self.circleId = circleId
        self.userId = userId
        if DemoContent.isActive {
            if stamps.isEmpty { stamps = DemoContent.stamps }
            activityDates = DemoContent.hangouts.map(\.createdAt)
                + DemoContent.postcards.map(\.createdAt)
            return
        }
        listeners = [
            stampRepo.listenStamps(circleId: circleId) { [weak self] stamps in
                Task { @MainActor in self?.stamps = stamps }
            },
            hangoutRepo.listenHangouts(circleId: circleId) { [weak self] hangouts in
                Task { @MainActor in
                    self?.hangoutDates = hangouts.filter { $0.status == .done }.map { $0.startsAt ?? $0.createdAt }
                    self?.rebuildActivity()
                }
            },
            postcardRepo.listenPostcards(circleId: circleId) { [weak self] postcards in
                Task { @MainActor in
                    self?.postcardDates = postcards.map(\.createdAt)
                    self?.rebuildActivity()
                }
            },
            circleRepo.listenIncomingRequests(circleId: circleId) { [weak self] requests in
                Task { @MainActor in self?.incomingRequests = requests }
            },
        ].compactMap { $0 }
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners = []
    }

    private func rebuildActivity() {
        activityDates = hangoutDates + postcardDates
    }

    // MARK: - circle friends

    func loadFriends(_ circle: FriendCircle) {
        let ids = circle.friendCircleIds ?? []
        guard ids != loadedFriendIds else { return }
        loadedFriendIds = ids
        guard !ids.isEmpty else {
            friendCircles = []
            return
        }
        run {
            var found: [FriendCircle] = []
            for id in ids {
                if let friend = try? await self.circleRepo.fetchCircle(id: id) {
                    found.append(friend)
                }
            }
            await MainActor.run { self.friendCircles = found }
        }
    }

    func acceptRequest(_ request: CircleFriendRequest) {
        run { try await self.circleRepo.acceptFriendRequest(request, myCircleId: self.circleId) }
    }

    func declineRequest(_ request: CircleFriendRequest) {
        run { try await self.circleRepo.declineFriendRequest(request, myCircleId: self.circleId) }
    }

    func syncSentRequests(_ circle: FriendCircle) {
        guard !(circle.sentFriendRequests ?? []).isEmpty else { return }
        run { try await self.circleRepo.syncSentRequests(myCircle: circle) }
    }

    func stamps(for userId: String) -> [Stamp] {
        stamps.filter { $0.userId == userId }
    }

    func addBucketListItem(_ label: String, circle: FriendCircle) {
        let trimmed = label.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let circleId = circle.id else { return }
        var items = circle.bucketList
        items.append(BucketListItem(id: UUID().uuidString, label: trimmed, done: false, doneHangoutId: nil))
        updateBucketList(items, circleId: circleId)
    }

    func toggleBucketListItem(_ itemId: String, circle: FriendCircle) {
        guard let circleId = circle.id else { return }
        var items = circle.bucketList
        for i in items.indices where items[i].id == itemId {
            items[i].done.toggle()
            if !items[i].done { items[i].doneHangoutId = nil }
        }
        updateBucketList(items, circleId: circleId)
    }

    func updateCircleProfile(name: String, coverEmoji: String, bio: String?, isPublic: Bool, circleId: String) {
        run { try await self.circleRepo.updateCircleProfile(name: name, coverEmoji: coverEmoji, bio: bio, isPublic: isPublic, circleId: circleId) }
    }

    func updateShowcase(postcardIds: [String]) {
        run { try await self.circleRepo.updateShowcase(postcardIds: postcardIds, circleId: self.circleId) }
    }

    private func updateBucketList(_ items: [BucketListItem], circleId: String) {
        run { try await self.circleRepo.updateBucketList(items, circleId: circleId) }
    }

    private func run(_ work: @escaping () async throws -> Void) {
        if DemoContent.isActive { return }  // circle doc edits need a live backend
        Task {
            do {
                try await work()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
