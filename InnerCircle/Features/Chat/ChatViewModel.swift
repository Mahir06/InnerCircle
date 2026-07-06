import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var drops: [Message] = []
    @Published var errorMessage: String?

    private let chatRepo = ChatRepository()
    private let sparkRepo = SparkRepository()
    private var listener: ListenerRegistration?
    private(set) var circleId = ""
    private(set) var userId = ""

    func start(circleId: String, userId: String) {
        guard self.circleId != circleId || listener == nil else { return }
        stop()
        self.circleId = circleId
        self.userId = userId
        if DemoContent.isActive {
            drops = DemoContent.drops
            return
        }
        listener = chatRepo.listenMessages(circleId: circleId) { [weak self] drops in
            Task { @MainActor in
                self?.drops = drops
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func sendText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        run { try await self.chatRepo.sendText(trimmed, senderId: self.userId, circleId: self.circleId) }
    }

    func sendPoll(question: String, options: [String], allowsMultiple: Bool) {
        run {
            try await self.chatRepo.sendPoll(
                question: question,
                optionLabels: options,
                allowsMultipleAnswers: allowsMultiple,
                senderId: self.userId,
                circleId: self.circleId
            )
        }
    }

    func dropSpark() {
        guard let spark = sparkRepo.randomSpark() else { return }
        run { try await self.chatRepo.sendSpark(spark, senderId: self.userId, circleId: self.circleId) }
    }

    func vote(message: Message, optionId: String) {
        guard let messageId = message.id else { return }
        run {
            try await self.chatRepo.votePoll(
                messageId: messageId,
                optionId: optionId,
                userId: self.userId,
                circleId: self.circleId
            )
        }
    }

    func answerSpark(message: Message, answer: String) {
        guard let messageId = message.id else { return }
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        run {
            try await self.chatRepo.answerSpark(
                messageId: messageId,
                answer: trimmed,
                userId: self.userId,
                circleId: self.circleId
            )
        }
    }

    func toggleReaction(message: Message, emoji: String) {
        guard let messageId = message.id else { return }
        let reacted = message.reactions?[emoji]?.contains(userId) ?? false
        run {
            try await self.chatRepo.toggleReaction(
                messageId: messageId,
                emoji: emoji,
                userId: self.userId,
                currentlyReacted: reacted,
                circleId: self.circleId
            )
        }
    }

    func saveQuote(message: Message) {
        guard let text = message.text else { return }
        run {
            try await self.chatRepo.saveQuote(
                text: text,
                authorId: message.senderId,
                savedBy: self.userId,
                circleId: self.circleId
            )
        }
    }

    private func run(_ work: @escaping () async throws -> Void) {
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
