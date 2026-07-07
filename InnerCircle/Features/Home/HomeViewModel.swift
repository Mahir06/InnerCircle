import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var hangouts: [Hangout] = []
    @Published var postcards: [Postcard] = []
    @Published var drops: [Message] = []
    @Published var activeSessions: [GameSession] = []
    @Published var todaySpark: Spark?
    @Published var chatHighlights: String?
    @Published var errorMessage: String?

    private let hangoutRepo = HangoutRepository()
    private let postcardRepo = PostcardRepository()
    private let chatRepo = ChatRepository()
    private let sparkRepo = SparkRepository()
    private let userRepo = UserRepository()
    private let gameRepo = GameSessionRepository()
    private let eventsRepo = EventsRepository()

    private var listeners: [ListenerRegistration] = []
    private(set) var circleId = ""
    private(set) var userId = ""
    private var started = false
    private var digestedCount = -1

    func start(circleId: String, userId: String, memberName: @escaping (String) -> String) {
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
            refreshHighlights(memberName: memberName)
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
                Task { @MainActor in
                    self?.drops = items
                    self?.refreshHighlights(memberName: memberName)
                }
            },
            gameRepo.listenActiveSessions(circleId: circleId) { [weak self] sessions in
                Task { @MainActor in self?.activeSessions = sessions }
            },
        ].compactMap { $0 }
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners = []
        started = false
    }

    // MARK: feed picks

    var liveHangout: Hangout? {
        hangouts.first { $0.status == .live }
    }

    var nextHangout: Hangout? {
        hangouts
            .filter { $0.status == .planning }
            .sorted { ($0.startsAt ?? .distantFuture) < ($1.startsAt ?? .distantFuture) }
            .first
    }

    var openLobby: GameSession? {
        activeSessions.first { $0.state == .lobby }
    }

    var runningGame: GameSession? {
        activeSessions.first { $0.state == .active }
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

    var eventPick: VenueEvent? {
        eventsRepo.nearbyEvents().first { $0.startsAt > Date() }
    }

    var onThisDay: Postcard? {
        let calendar = Calendar.current
        let sealed = postcards.filter { $0.isSealed && !$0.isLockedCapsule }
        return sealed.first {
            calendar.dateComponents([.day], from: $0.createdAt).day
                == calendar.dateComponents([.day], from: Date()).day
                && !calendar.isDateInToday($0.createdAt)
        } ?? sealed.randomElement()
    }

    // MARK: chat highlights (the scribe's TL;DR of the last day)

    private func refreshHighlights(memberName: @escaping (String) -> String) {
        let dayAgo = Date().addingTimeInterval(-86400)
        let recent = drops.filter { $0.sentAt > dayAgo && $0.type != .system }
        guard recent.count >= 4 else {
            chatHighlights = nil
            return
        }
        guard recent.count != digestedCount else { return }
        digestedCount = recent.count
        Task {
            let digest = await AISummaryService.digest(
                messages: recent,
                title: "today in the chat",
                memberName: memberName
            )
            await MainActor.run { self.chatHighlights = digest }
        }
    }

    // MARK: actions

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

    // Today's spark becomes round one of a Hot Takes table.
    func playSparkAsGame() async -> String? {
        guard let spark = todaySpark,
              let game = OnlineGame.byId("hotTakes") else { return nil }
        do {
            return try await GameSessionViewModel.openTable(
                game: game, hostId: userId, circleId: circleId, firstPrompt: spark.prompt
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
