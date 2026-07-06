import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class CircleViewModel: ObservableObject {
    @Published var stamps: [Stamp] = []
    @Published var errorMessage: String?

    private let stampRepo = StampRepository()
    private let circleRepo = CircleRepository()
    private var stampsListener: ListenerRegistration?
    private(set) var circleId = ""
    private(set) var userId = ""

    func start(circleId: String, userId: String) {
        guard self.circleId != circleId || (stampsListener == nil && !DemoContent.isActive) else { return }
        stop()
        self.circleId = circleId
        self.userId = userId
        if DemoContent.isActive {
            if stamps.isEmpty { stamps = DemoContent.stamps }
            return
        }
        stampsListener = stampRepo.listenStamps(circleId: circleId) { [weak self] stamps in
            Task { @MainActor in
                self?.stamps = stamps
            }
        }
    }

    func stop() {
        stampsListener?.remove()
        stampsListener = nil
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

    func updateCircleProfile(name: String, coverEmoji: String, circleId: String) {
        run { try await self.circleRepo.updateCircleProfile(name: name, coverEmoji: coverEmoji, circleId: circleId) }
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
