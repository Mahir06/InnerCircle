import Foundation

// Demo mode: launch with IC_DEMO=1 while the backend is unconfigured to
// walk the full UI with sample data. Never active once Firebase is wired.
enum DemoContent {
    static var isActive: Bool {
        !FirebaseManager.shared.isConfigured
            && ProcessInfo.processInfo.environment["IC_DEMO"] == "1"
    }

    static let userId = "demo-mahir"

    static var user: AppUser {
        var user = AppUser.new(displayName: "Mahir")
        user.id = userId
        user.circleId = "demo-circle"
        user.idCard = IDCard(color: "sunset", emoji: "😎", tagline: "chief plan canceller")
        return user
    }

    static var members: [AppUser] {
        var prem = AppUser.new(displayName: "Prem")
        prem.id = "demo-prem"
        prem.circleId = "demo-circle"
        prem.idCard = IDCard(color: "grape", emoji: "🐸", tagline: "will bring snacks")
        prem.status = UserStatus(text: "free to hangout", emoji: "🟢", setAt: Date())

        var ana = AppUser.new(displayName: "Ananya")
        ana.id = "demo-ana"
        ana.circleId = "demo-circle"
        ana.idCard = IDCard(color: "mint", emoji: "🌵", tagline: "5 business days to reply")

        return [user, prem, ana]
    }

    static var circle: FriendCircle {
        var circle = FriendCircle.new(name: "the OG circle", coverEmoji: "🌀", creatorId: userId)
        circle.id = "demo-circle"
        circle.code = "DEMO42"
        circle.memberIds = members.compactMap(\.id)
        circle.stats = CircleStats(hangoutsCompleted: 7, restaurantsVisited: 4, placesVisited: 5)
        circle.bucketList = [
            BucketListItem(id: "b1", label: "go to Gokarna", done: false, doneHangoutId: nil),
            BucketListItem(id: "b2", label: "night on the beach", done: true, doneHangoutId: "demo-h0"),
            BucketListItem(id: "b3", label: "college in pyjamas", done: false, doneHangoutId: nil),
        ]
        return circle
    }

    static var drops: [Message] {
        [
            Message(id: "m1", senderId: "system", sentAt: date(-90), type: .system,
                    text: "Prem joined the circle 🎟️"),
            Message(id: "m2", senderId: "demo-prem", sentAt: date(-80), type: .text,
                    text: "yo who's up for biryani saturday"),
            Message(id: "m3", senderId: userId, sentAt: date(-75), type: .text,
                    text: "only if we go to the new place", reactions: ["🔥": ["demo-prem"]]),
            Message(id: "m4", senderId: "demo-ana", sentAt: date(-60), type: .poll,
                    poll: Poll(question: "saturday: biryani or pizza?", allowsMultipleAnswers: false, options: [
                        PollOption(id: "o1", label: "biryani obviously", voterIds: ["demo-prem", userId]),
                        PollOption(id: "o2", label: "pizza (wrong answer)", voterIds: ["demo-ana"]),
                    ])),
            Message(id: "m5", senderId: "demo-prem", sentAt: date(-30), type: .spark,
                    spark: SparkDrop(promptId: "s1",
                                     prompt: "what would this group's reality show be called?",
                                     kind: "question",
                                     answers: ["demo-prem": "keeping up with the cancellations"])),
            Message(id: "m6", senderId: "demo-ana", sentAt: date(-10), type: .hangoutInvite,
                    text: "biryani saturday 🍛", hangoutId: "demo-h1"),
        ]
    }

    static var hangouts: [Hangout] {
        var planning = Hangout.new(title: "biryani saturday 🍛", hostId: userId, mode: .custom)
        planning.id = "demo-h1"
        planning.startsAt = Date().addingTimeInterval(2 * 86400)
        planning.place = "the new place, indiranagar"
        planning.estCost = 500
        planning.rsvps = [userId: .going, "demo-prem": .going, "demo-ana": .maybe]
        planning.potluck = [
            PotluckItem(id: "p1", label: "raita (non negotiable)", claimedBy: "demo-prem"),
            PotluckItem(id: "p2", label: "cold drinks", claimedBy: nil),
        ]
        planning.tasks = [
            HangoutTask(id: "t1", label: "book the table", assignedTo: userId, done: false),
        ]
        planning.bucketListItemId = "b1"

        var randomizer = Hangout.new(title: "the shortlist decides 🎲", hostId: "demo-ana", mode: .randomizer)
        randomizer.id = "demo-h2"
        randomizer.shortlist = [
            ShortlistIdea(id: "s1", idea: "bowling", votes: ["demo-prem"]),
            ShortlistIdea(id: "s2", idea: "midnight drive", votes: ["demo-ana", "demo-prem"]),
            ShortlistIdea(id: "s3", idea: "arcade takeover", votes: []),
        ]

        var requested = Hangout.new(title: "mystery plan by Mahir", hostId: "demo-prem", mode: .request)
        requested.id = "demo-h3"
        requested.requestedFrom = userId
        requested.requestStatus = .pending

        var live = Hangout.new(title: "beach day 🌊", hostId: "demo-prem", mode: .howAboutWe)
        live.id = "demo-h4"
        live.status = .live
        live.rsvps = [userId: .going, "demo-prem": .going, "demo-ana": .going]
        live.arrivals = ["demo-prem": Date().addingTimeInterval(-1800)]

        var done = Hangout.new(title: "game night 🎲", hostId: "demo-ana", mode: .custom)
        done.id = "demo-h5"
        done.status = .done
        done.createdAt = Date().addingTimeInterval(-7 * 86400)

        return [planning, randomizer, requested, live, done]
    }

    static var postcards: [Postcard] {
        let open = Postcard(
            id: "demo-pc1",
            hangoutId: "demo-h5",
            hangoutTitle: "game night 🎲",
            templateId: "classic",
            blocks: [
                PostcardBlock(id: "pb1", type: .text,
                              content: "prem flipped the board when he lost. again.",
                              authorId: "demo-ana", position: 0),
                PostcardBlock(id: "pb2", type: .sticker, content: "😂", authorId: userId, position: 1),
            ],
            contributorIds: ["demo-ana", userId],
            createdAt: Date().addingTimeInterval(-14 * 3600),
            sealsAt: Date().addingTimeInterval(34 * 3600),
            framedBy: "demo-ana"
        )
        let sealed = Postcard(
            id: "demo-pc2",
            hangoutId: "demo-h0",
            hangoutTitle: "night on the beach 🌊",
            templateId: "classic",
            blocks: [
                PostcardBlock(id: "pb3", type: .text,
                              content: "we stayed till sunrise and regretted nothing (everything)",
                              authorId: "demo-prem", position: 0),
                PostcardBlock(id: "pb4", type: .sticker, content: "🌅", authorId: "demo-ana", position: 1),
            ],
            contributorIds: ["demo-prem", "demo-ana", userId],
            createdAt: Date().addingTimeInterval(-40 * 86400),
            sealsAt: Date().addingTimeInterval(-38 * 86400),
            sealedAt: Date().addingTimeInterval(-38 * 86400),
            framedBy: "demo-prem"
        )
        let capsule = Postcard(
            id: "demo-pc3",
            hangoutId: "demo-hx",
            hangoutTitle: "new year's pact 🎆",
            templateId: "classic",
            blocks: [],
            contributorIds: [userId],
            createdAt: Date().addingTimeInterval(-10 * 86400),
            sealsAt: Date().addingTimeInterval(-8 * 86400),
            sealedAt: Date().addingTimeInterval(-8 * 86400),
            unlockAt: Date().addingTimeInterval(300 * 86400),
            framedBy: userId
        )
        return [open, sealed, capsule]
    }

    static var stamps: [Stamp] {
        [
            Stamp(id: "st1", userId: userId, kind: .host, hangoutId: "demo-h5",
                  awardedAt: Date().addingTimeInterval(-6 * 86400)),
            Stamp(id: "st2", userId: "demo-prem", kind: .firstOneIn, hangoutId: "demo-h5",
                  awardedAt: Date().addingTimeInterval(-6 * 86400)),
            Stamp(id: "st3", userId: "demo-ana", kind: .scribe, hangoutId: "demo-h5",
                  awardedAt: Date().addingTimeInterval(-5 * 86400)),
            Stamp(id: "st4", userId: userId, kind: .firstOneIn, hangoutId: "demo-h0",
                  awardedAt: Date().addingTimeInterval(-39 * 86400)),
        ]
    }

    private static func date(_ minutes: Double) -> Date {
        Date().addingTimeInterval(minutes * 60)
    }
}
