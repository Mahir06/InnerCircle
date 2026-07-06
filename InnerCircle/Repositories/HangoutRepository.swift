import Foundation
import FirebaseFirestore

// Firestore access for circles/{circleId}/hangouts
final class HangoutRepository {
    private var db: Firestore { FirebaseManager.shared.db }
    private var configured: Bool { FirebaseManager.shared.isConfigured }

    private func hangouts(_ circleId: String) -> CollectionReference {
        db.collection("circles").document(circleId).collection("hangouts")
    }

    func listenHangouts(circleId: String, onChange: @escaping ([Hangout]) -> Void) -> ListenerRegistration? {
        guard configured else {
            onChange([])
            return nil
        }
        return hangouts(circleId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { try? $0.data(as: Hangout.self) } ?? []
                onChange(items)
            }
    }

    @discardableResult
    func createHangout(_ hangout: Hangout, circleId: String) async throws -> String {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let ref = try hangouts(circleId).addDocument(from: hangout)
        return ref.documentID
    }

    func updateRSVP(hangoutId: String, userId: String, rsvp: RSVP, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await hangouts(circleId).document(hangoutId).updateData([
            "rsvps.\(userId)": rsvp.rawValue
        ])
    }

    func updatePoster(hangoutId: String, poster: Poster, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await hangouts(circleId).document(hangoutId).updateData([
            "poster": ["templateId": poster.templateId, "colorway": poster.colorway, "emoji": poster.emoji]
        ])
    }

    func updateDetails(hangoutId: String, title: String, place: String?, startsAt: Date?, estCost: Double?, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        var fields: [String: Any] = ["title": title]
        fields["place"] = place ?? FieldValue.delete()
        fields["startsAt"] = startsAt.map { Timestamp(date: $0) } ?? FieldValue.delete()
        fields["estCost"] = estCost ?? FieldValue.delete()
        try await hangouts(circleId).document(hangoutId).updateData(fields)
    }

    func addPotluckItem(hangoutId: String, label: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await hangouts(circleId).document(hangoutId).updateData([
            "potluck": FieldValue.arrayUnion([["id": UUID().uuidString, "label": label]])
        ])
    }

    // Claim (or unclaim) a potluck item. Transaction so two people can't
    // both end up bringing the ice.
    func togglePotluckClaim(hangoutId: String, itemId: String, userId: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let ref = hangouts(circleId).document(hangoutId)
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard var potluck = snapshot.data()?["potluck"] as? [[String: Any]] else { return nil }
                for i in potluck.indices where potluck[i]["id"] as? String == itemId {
                    let claimedBy = potluck[i]["claimedBy"] as? String
                    if claimedBy == userId {
                        potluck[i]["claimedBy"] = nil
                    } else if claimedBy == nil {
                        potluck[i]["claimedBy"] = userId
                    }
                }
                transaction.updateData(["potluck": potluck], forDocument: ref)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    func addTask(hangoutId: String, label: String, assignedTo: String?, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        var item: [String: Any] = ["id": UUID().uuidString, "label": label, "done": false]
        if let assignedTo { item["assignedTo"] = assignedTo }
        try await hangouts(circleId).document(hangoutId).updateData([
            "tasks": FieldValue.arrayUnion([item])
        ])
    }

    func toggleTaskDone(hangoutId: String, taskId: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let ref = hangouts(circleId).document(hangoutId)
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard var tasks = snapshot.data()?["tasks"] as? [[String: Any]] else { return nil }
                for i in tasks.indices where tasks[i]["id"] as? String == taskId {
                    tasks[i]["done"] = !(tasks[i]["done"] as? Bool ?? false)
                }
                transaction.updateData(["tasks": tasks], forDocument: ref)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    // Request mode: the asked friend takes over hosting.
    func acceptPlanRequest(hangoutId: String, accepterId: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await hangouts(circleId).document(hangoutId).updateData([
            "requestStatus": RequestStatus.accepted.rawValue,
            "hostId": accepterId,
        ])
    }

    // Randomizer mode: toggle your vote on a shortlist idea.
    func voteShortlist(hangoutId: String, ideaId: String, userId: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        let ref = hangouts(circleId).document(hangoutId)
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard var shortlist = snapshot.data()?["shortlist"] as? [[String: Any]] else { return nil }
                for i in shortlist.indices where shortlist[i]["id"] as? String == ideaId {
                    var votes = shortlist[i]["votes"] as? [String] ?? []
                    if votes.contains(userId) {
                        votes.removeAll { $0 == userId }
                    } else {
                        votes.append(userId)
                    }
                    shortlist[i]["votes"] = votes
                }
                transaction.updateData(["shortlist": shortlist], forDocument: ref)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    // Randomizer mode: the winning idea becomes the plan.
    func lockInShortlistWinner(hangoutId: String, winningIdea: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await hangouts(circleId).document(hangoutId).updateData([
            "title": winningIdea
        ])
    }

    func startHangout(hangoutId: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await hangouts(circleId).document(hangoutId).updateData([
            "status": HangoutStatus.live.rawValue
        ])
    }

    // "i'm here" — first arrival earns First One In (awarded in the stamps block)
    func markArrival(hangoutId: String, userId: String, circleId: String) async throws {
        guard configured else { throw FirebaseManager.notConfiguredError }
        try await hangouts(circleId).document(hangoutId).updateData([
            "arrivals.\(userId)": Timestamp(date: Date())
        ])
    }

    // Ends the hangout: status done, bump circle stats, check off the
    // bucket list item if this plan was tagged with one.
    func endHangout(_ hangout: Hangout, circleId: String) async throws {
        guard configured, let hangoutId = hangout.id else { throw FirebaseManager.notConfiguredError }
        let batch = db.batch()
        batch.updateData(["status": HangoutStatus.done.rawValue], forDocument: hangouts(circleId).document(hangoutId))
        let circleRef = db.collection("circles").document(circleId)
        batch.updateData(["stats.hangoutsCompleted": FieldValue.increment(Int64(1))], forDocument: circleRef)
        try await batch.commit()

        if let itemId = hangout.bucketListItemId {
            try await checkOffBucketListItem(itemId: itemId, hangoutId: hangoutId, circleId: circleId)
        }
    }

    private func checkOffBucketListItem(itemId: String, hangoutId: String, circleId: String) async throws {
        let ref = db.collection("circles").document(circleId)
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard var bucketList = snapshot.data()?["bucketList"] as? [[String: Any]] else { return nil }
                for i in bucketList.indices where bucketList[i]["id"] as? String == itemId {
                    bucketList[i]["done"] = true
                    bucketList[i]["doneHangoutId"] = hangoutId
                }
                transaction.updateData(["bucketList": bucketList], forDocument: ref)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }
}
