import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var drops: [Message] = []
    @Published var errorMessage: String?

    private let chatRepo = ChatRepository()
    private let sparkRepo = SparkRepository()
    private let postcardRepo = PostcardRepository()
    private var listener: ListenerRegistration?
    private(set) var circleId = ""
    private(set) var userId = ""
    private(set) var hangoutId: String?   // nil = the circle's main chat

    func start(circleId: String, userId: String, hangoutId: String? = nil) {
        guard self.circleId != circleId || self.hangoutId != hangoutId || listener == nil else { return }
        stop()
        self.circleId = circleId
        self.userId = userId
        self.hangoutId = hangoutId
        if DemoContent.isActive {
            drops = hangoutId == nil ? DemoContent.drops : DemoContent.hangoutDrops
            return
        }
        listener = chatRepo.listenMessages(circleId: circleId, hangoutId: hangoutId) { [weak self] drops in
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
        run { try await self.chatRepo.sendText(trimmed, senderId: self.userId, circleId: self.circleId, hangoutId: self.hangoutId) }
    }

    // Hangout chat only: digest the chat with the AI scribe and press it
    // into the hangout's postcard as an aiSummary block.
    @Published var storySealed = false

    func sealStory(hangoutTitle: String, memberName: @escaping (String) -> String) {
        guard let hangoutId else { return }
        let messages = drops
        run {
            let summary = await AISummaryService.digest(messages: messages, title: hangoutTitle, memberName: memberName)
            guard let postcard = try await self.postcardRepo.fetchPostcard(hangoutId: hangoutId, circleId: self.circleId),
                  let postcardId = postcard.id else {
                throw NSError(domain: "InnerCircle", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "no postcard for this hangout yet. end the hangout first"
                ])
            }
            let block = PostcardBlock(
                id: UUID().uuidString,
                type: .aiSummary,
                content: summary,
                authorId: self.userId,
                position: postcard.blocks.count
            )
            try await self.postcardRepo.addBlock(block, postcardId: postcardId, circleId: self.circleId)
            try await self.chatRepo.sendSystem("the scribe wrote this chat into the postcard ✍️", circleId: self.circleId, hangoutId: hangoutId)
            await MainActor.run { self.storySealed = true }
        }
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
                circleId: self.circleId,
                hangoutId: self.hangoutId
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
                circleId: self.circleId,
                hangoutId: self.hangoutId
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
                circleId: self.circleId,
                hangoutId: self.hangoutId
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
