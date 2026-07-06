import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class HangoutsViewModel: ObservableObject {
    @Published var hangouts: [Hangout] = []
    @Published var errorMessage: String?

    private let repo = HangoutRepository()
    private let chatRepo = ChatRepository()
    private let postcardRepo = PostcardRepository()
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
            if hangouts.isEmpty { hangouts = DemoContent.hangouts }
            return
        }
        listener = repo.listenHangouts(circleId: circleId) { [weak self] hangouts in
            Task { @MainActor in
                self?.hangouts = hangouts
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func hangout(_ id: String?) -> Hangout? {
        hangouts.first { $0.id == id }
    }

    func create(_ hangout: Hangout) {
        if DemoContent.isActive {
            var copy = hangout
            copy.id = UUID().uuidString
            hangouts.insert(copy, at: 0)
            return
        }
        run {
            let id = try await self.repo.createHangout(hangout, circleId: self.circleId)
            // every new plan drops an invite in chat
            let title = hangout.mode == .request
                ? "\(hangout.title) (someone got voluntold)"
                : hangout.title
            try await self.chatRepo.sendHangoutInvite(
                hangoutId: id,
                title: title,
                senderId: self.userId,
                circleId: self.circleId
            )
        }
    }

    func rsvp(_ hangout: Hangout, _ answer: RSVP) {
        mutate(hangout) { $0.rsvps[self.userId] = answer } remote: {
            try await self.repo.updateRSVP(hangoutId: $0, userId: self.userId, rsvp: answer, circleId: self.circleId)
        }
    }

    func updatePoster(_ hangout: Hangout, poster: Poster) {
        mutate(hangout) { $0.poster = poster } remote: {
            try await self.repo.updatePoster(hangoutId: $0, poster: poster, circleId: self.circleId)
        }
    }

    func addPotluckItem(_ hangout: Hangout, label: String) {
        let trimmed = label.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        mutate(hangout) {
            $0.potluck.append(PotluckItem(id: UUID().uuidString, label: trimmed, claimedBy: nil))
        } remote: {
            try await self.repo.addPotluckItem(hangoutId: $0, label: trimmed, circleId: self.circleId)
        }
    }

    func togglePotluckClaim(_ hangout: Hangout, itemId: String) {
        mutate(hangout) { h in
            for i in h.potluck.indices where h.potluck[i].id == itemId {
                if h.potluck[i].claimedBy == self.userId {
                    h.potluck[i].claimedBy = nil
                } else if h.potluck[i].claimedBy == nil {
                    h.potluck[i].claimedBy = self.userId
                }
            }
        } remote: {
            try await self.repo.togglePotluckClaim(hangoutId: $0, itemId: itemId, userId: self.userId, circleId: self.circleId)
        }
    }

    func addTask(_ hangout: Hangout, label: String, assignedTo: String?) {
        let trimmed = label.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        mutate(hangout) {
            $0.tasks.append(HangoutTask(id: UUID().uuidString, label: trimmed, assignedTo: assignedTo, done: false))
        } remote: {
            try await self.repo.addTask(hangoutId: $0, label: trimmed, assignedTo: assignedTo, circleId: self.circleId)
        }
    }

    func toggleTaskDone(_ hangout: Hangout, taskId: String) {
        mutate(hangout) { h in
            for i in h.tasks.indices where h.tasks[i].id == taskId {
                h.tasks[i].done.toggle()
            }
        } remote: {
            try await self.repo.toggleTaskDone(hangoutId: $0, taskId: taskId, circleId: self.circleId)
        }
    }

    func acceptPlanRequest(_ hangout: Hangout) {
        mutate(hangout) {
            $0.requestStatus = .accepted
            $0.hostId = self.userId
        } remote: {
            try await self.repo.acceptPlanRequest(hangoutId: $0, accepterId: self.userId, circleId: self.circleId)
        }
    }

    func voteShortlist(_ hangout: Hangout, ideaId: String) {
        mutate(hangout) { h in
            guard var shortlist = h.shortlist else { return }
            for i in shortlist.indices where shortlist[i].id == ideaId {
                if shortlist[i].votes.contains(self.userId) {
                    shortlist[i].votes.removeAll { $0 == self.userId }
                } else {
                    shortlist[i].votes.append(self.userId)
                }
            }
            h.shortlist = shortlist
        } remote: {
            try await self.repo.voteShortlist(hangoutId: $0, ideaId: ideaId, userId: self.userId, circleId: self.circleId)
        }
    }

    func lockInShortlistWinner(_ hangout: Hangout) {
        guard let winner = hangout.shortlist?.max(by: { $0.votes.count < $1.votes.count }) else { return }
        mutate(hangout) { $0.title = winner.idea } remote: {
            try await self.repo.lockInShortlistWinner(hangoutId: $0, winningIdea: winner.idea, circleId: self.circleId)
        }
    }

    func startHangout(_ hangout: Hangout) {
        mutate(hangout) { $0.status = .live } remote: {
            try await self.repo.startHangout(hangoutId: $0, circleId: self.circleId)
        }
    }

    func markArrival(_ hangout: Hangout) {
        mutate(hangout) { $0.arrivals[self.userId] = Date() } remote: {
            try await self.repo.markArrival(hangoutId: $0, userId: self.userId, circleId: self.circleId)
        }
    }

    // Ending a hangout opens the postcard: the sealing ritual starts now.
    func endHangout(_ hangout: Hangout) {
        mutate(hangout) { $0.status = .done } remote: { _ in
            try await self.repo.endHangout(hangout, circleId: self.circleId)
            try await self.postcardRepo.createPostcard(hangout: hangout, framedBy: self.userId, circleId: self.circleId)
            try await self.chatRepo.sendSystem(
                "a postcard for \"\(hangout.title)\" is open! 2 days before the envelope seals ✉️",
                circleId: self.circleId
            )
            // stamps v1: the host made it happen, the earliest arrival wins punctuality
            try await self.stampRepo.awardStamp(kind: .host, userId: hangout.hostId, hangoutId: hangout.id, circleId: self.circleId)
            if let firstIn = hangout.arrivals.min(by: { $0.value < $1.value })?.key {
                try await self.stampRepo.awardStamp(kind: .firstOneIn, userId: firstIn, hangoutId: hangout.id, circleId: self.circleId)
            }
        }
    }

    // Demo mode edits the local array; live mode calls Firestore and the
    // snapshot listener refreshes the array.
    private func mutate(_ hangout: Hangout, local: @escaping (inout Hangout) -> Void, remote: @escaping (String) async throws -> Void) {
        guard let id = hangout.id else { return }
        if DemoContent.isActive {
            for i in hangouts.indices where hangouts[i].id == id {
                local(&hangouts[i])
            }
            return
        }
        run { try await remote(id) }
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
