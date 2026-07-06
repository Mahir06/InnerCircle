import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class MailboxViewModel: ObservableObject {
    @Published var postcards: [Postcard] = []
    @Published var errorMessage: String?

    private let repo = PostcardRepository()
    private let storageRepo = StorageRepository()
    private let stampRepo = StampRepository()
    private var listener: ListenerRegistration?
    private(set) var circleId = ""
    private(set) var userId = ""

    func start(circleId: String, userId: String) {
        guard self.circleId != circleId || (listener == nil && !DemoContent.isActive) else { return }
        stop()
        self.circleId = circleId
        self.userId = userId
        if DemoContent.isActive {
            if postcards.isEmpty { postcards = DemoContent.postcards }
            return
        }
        listener = repo.listenPostcards(circleId: circleId) { [weak self] postcards in
            Task { @MainActor in
                self?.postcards = postcards
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func postcard(_ id: String?) -> Postcard? {
        postcards.first { $0.id == id }
    }

    // Random memory resurfacing: prefer a sealed card from this same
    // date in a past month/year, else any sealed one.
    var onThisDay: Postcard? {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.day], from: Date()).day
        let sealed = postcards.filter { $0.isSealed && !$0.isLockedCapsule }
        let sameDay = sealed.filter {
            calendar.dateComponents([.day], from: $0.createdAt).day == today
                && !calendar.isDateInToday($0.createdAt)
        }
        return sameDay.randomElement() ?? sealed.randomElement()
    }

    func postcards(on date: Date) -> [Postcard] {
        postcards.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }
    }

    func addTextBlock(_ text: String, to postcard: Postcard) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        addBlock(type: .text, content: trimmed, to: postcard)
    }

    func addStickerBlock(_ emoji: String, to postcard: Postcard) {
        addBlock(type: .sticker, content: emoji, to: postcard)
    }

    func addPhotoBlock(_ data: Data, to postcard: Postcard) {
        guard let postcardId = postcard.id else { return }
        run {
            let url = try await self.storageRepo.uploadPostcardPhoto(data, circleId: self.circleId, postcardId: postcardId)
            self.addBlock(type: .photo, content: url.absoluteString, to: postcard)
        }
    }

    func setTimeCapsule(_ postcard: Postcard, unlockAt: Date?) {
        guard let id = postcard.id else { return }
        if DemoContent.isActive {
            mutateLocal(id) { $0.unlockAt = unlockAt }
            return
        }
        run { try await self.repo.setTimeCapsule(postcardId: id, unlockAt: unlockAt, circleId: self.circleId) }
    }

    private func addBlock(type: BlockType, content: String, to postcard: Postcard) {
        guard let id = postcard.id else { return }
        let block = PostcardBlock(
            id: UUID().uuidString,
            type: type,
            content: content,
            authorId: userId,
            position: postcard.blocks.count
        )
        if DemoContent.isActive {
            mutateLocal(id) {
                $0.blocks.append(block)
                if !$0.contributorIds.contains(userId) { $0.contributorIds.append(userId) }
            }
            return
        }
        let firstContribution = postcard.blocks.isEmpty
        run {
            try await self.repo.addBlock(block, postcardId: id, circleId: self.circleId)
            // the Scribe keeps the memory alive: first block on the postcard
            if firstContribution {
                try await self.stampRepo.awardStamp(kind: .scribe, userId: self.userId, hangoutId: postcard.hangoutId, circleId: self.circleId)
            }
        }
    }

    private func mutateLocal(_ id: String, _ change: (inout Postcard) -> Void) {
        for i in postcards.indices where postcards[i].id == id {
            change(&postcards[i])
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
