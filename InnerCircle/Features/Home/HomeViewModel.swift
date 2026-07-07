import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var hangouts: [Hangout] = []
    @Published var postcards: [Postcard] = []
    @Published var drops: [Message] = []
    @Published var todaySpark: Spark?
    @Published var errorMessage: String?

    private let hangoutRepo = HangoutRepository()
    private let postcardRepo = PostcardRepository()
    private let chatRepo = ChatRepository()
    private let sparkRepo = SparkRepository()
    private let userRepo = UserRepository()

    private var listeners: [ListenerRegistration] = []
    private(set) var circleId = ""
    private(set) var userId = ""
    private var started = false

    func start(circleId: String, userId: String) {
        guard self.circleId != circleId || !started else { return }
        stop()
        started = true
        self.circleId = circleId
        self.userId = userId

        Task {
            todaySpark = await sparkRepo.todaySpark()
        }

        if DemoContent.isActive {
            hangouts = DemoContent.hangouts
            postcards = DemoContent.postcards
            drops = DemoContent.drops
            return
        }
        listeners = [
            hangoutRepo.listenHangouts(circleId: circleId) { [weak self] items in
                Task { @MainActor in self?.hangouts = items }
            },
            postcardRepo.listenPostcards(circleId: circleId) { [weak self] items in
                Task { @MainActor in self?.postcards = items }
            },
            chatRepo.listenMessages(circleId: circleId) { [weak self] items in
                Task { @MainActor in self?.drops = items }
            },
        ].compactMap { $0 }
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners = []
        started = false
    }

    // MARK: home card picks

    var nextHangout: Hangout? {
        let active = hangouts.filter { $0.status != .done }
        if let live = active.first(where: { $0.status == .live }) { return live }
        return active
            .sorted { ($0.startsAt ?? .distantFuture) < ($1.startsAt ?? .distantFuture) }
            .first
    }

    var expiringPostcard: Postcard? {
        postcards
            .filter { !$0.isSealed }
            .min { $0.sealsAt < $1.sealsAt }
    }

    var activePoll: Message? {
        drops.last { $0.type == .poll }
    }

    var latestSparkDrop: Message? {
        drops.last { $0.type == .spark && !($0.spark?.answers.isEmpty ?? true) }
    }

    func setStatus(text: String, emoji: String) {
        let status = UserStatus(text: text, emoji: emoji, setAt: Date())
        if DemoContent.isActive { return }
        Task {
            do {
                try await userRepo.updateStatus(status, uid: userId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
