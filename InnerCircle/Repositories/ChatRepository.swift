import Foundation
import FirebaseFirestore

// Firestore access for circles/{circleId}/messages and, when a hangoutId
// is given, the hangout's own chat at circles/{id}/hangouts/{hid}/messages.
final class ChatRepository {
    private var db: Firestore { FirebaseManager.shared.db }
    private var configured: Bool { FirebaseManager.shared.isConfigured }

    private func messages(_ circleId: String, hangoutId: String? = nil) -> CollectionReference {
        let circle = db.collection("circles").document(circleId)
        if let hangoutId {
            return circle.collection("hangouts").document(hangoutId).collection("messages")
        }
        return circle.collection("messages")
    }

    // Last 100 drops, oldest first.
    func listenMessages(circleId: String, hangoutId: String? = nil, onChange: @escaping ([Message]) -> Void) -> ListenerRegistration? {
        guard configured else {
            onChange([])
            return nil
        }
        return messages(circleId, hangoutId: hangoutId)
            .order(by: "sentAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, _ in
                let drops = snapshot?.documents.compactMap { try? $0.data(as: Message.self) } ?? []
                onChange(drops.reversed())
            }
    }

    func sendText(_ text: String, senderId: String, circleId: String, hangoutId: String? = nil) async throws {
        try await send(Message(senderId: senderId, sentAt: Date(), type: .text, text: text), circleId: circleId, hangoutId: hangoutId)
    }

    func sendSystem(_ text: String, circleId: String, hangoutId: String? = nil) async throws {
        try await send(Message(senderId: "system", sentAt: Date(), type: .system, text: text), circleId: circleId, hangoutId: hangoutId)
    }

    func sendPoll(question: String, optionLabels: [String], allowsMultipleAnswers: Bool, senderId: String, circleId: String) async throws {
        let poll = Poll(
            question: question,
            allowsMultipleAnswers: allowsMultipleAnswers,
            options: optionLabels.map { PollOption(id: UUID().uuidString, label: $0, voterIds: []) }
        )
        try await send(Message(senderId: senderId, sentAt: Date(), type: .poll, poll: poll), circleId: circleId)
    }

    func sendSpark(_ spark: Spark, senderId: String, circleId: String) async throws {
        let drop = SparkDrop(
            promptId: spark.id ?? UUID().uuidString,
            prompt: spark.prompt,
            kind: spark.kind.rawValue,
            answers: [:]
        )
        try await send(Message(senderId: senderId, sentAt: Date(), type: .spark, spark: drop), circleId: circleId)
    }

    func sendHangoutInvite(hangoutId: String, title: String, senderId: String, circleId: String) async throws {
        try await send(
            Message(senderId: senderId, sentAt: Date(), type: .hangoutInvite, text: title, hangoutId: hangoutId),
            circleId: circleId
        )
    }

    private func send(_ message: Message, circleId: String, hangoutId: String? = nil) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        _ = try messages(circleId, hangoutId: hangoutId).addDocument(from: message)
    }

    // Tap an option to vote; tap again to unvote. Single-answer polls
    // move your vote. Runs in a transaction so nobody's vote is lost.
    func votePoll(messageId: String, optionId: String, userId: String, circleId: String, hangoutId: String? = nil) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let ref = messages(circleId, hangoutId: hangoutId).document(messageId)
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard var poll = snapshot.data()?["poll"] as? [String: Any],
                      var options = poll["options"] as? [[String: Any]] else { return nil }
                let allowsMultiple = poll["allowsMultipleAnswers"] as? Bool ?? false
                for i in options.indices {
                    var voters = options[i]["voterIds"] as? [String] ?? []
                    if options[i]["id"] as? String == optionId {
                        if voters.contains(userId) {
                            voters.removeAll { $0 == userId }
                        } else {
                            voters.append(userId)
                        }
                    } else if !allowsMultiple {
                        voters.removeAll { $0 == userId }
                    }
                    options[i]["voterIds"] = voters
                }
                poll["options"] = options
                transaction.updateData(["poll": poll], forDocument: ref)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    func answerSpark(messageId: String, answer: String, userId: String, circleId: String, hangoutId: String? = nil) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await messages(circleId, hangoutId: hangoutId).document(messageId).updateData([
            "spark.answers.\(userId)": answer
        ])
    }

    func toggleReaction(messageId: String, emoji: String, userId: String, currentlyReacted: Bool, circleId: String, hangoutId: String? = nil) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let value: FieldValue = currentlyReacted
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId])
        try await messages(circleId, hangoutId: hangoutId).document(messageId).updateData([
            "reactions.\(emoji)": value
        ])
    }

    // "hall of fame" quotes live on the circle doc
    func saveQuote(text: String, authorId: String, savedBy: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await db.collection("circles").document(circleId).updateData([
            "quotesArchive": FieldValue.arrayUnion([[
                "id": UUID().uuidString,
                "text": text,
                "authorId": authorId,
                "savedBy": savedBy,
                "at": Timestamp(date: Date()),
            ]])
        ])
    }
}
