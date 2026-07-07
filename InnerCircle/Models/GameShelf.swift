import Foundation

// The Game Shelf. Offline games are pure content: the phone is the
// card dealer. Online games run as Firestore sessions (Week 1).
nonisolated struct OfflineGame: Identifiable, Equatable {
    let id: String
    let title: String
    let emoji: String
    let tagline: String
    let colorway: String
    let decks: [GameDeck]

    var allCards: [String] { decks.flatMap(\.cards) }
}

nonisolated struct GameDeck: Identifiable, Equatable {
    let id: String
    let name: String
    let cards: [String]
}

// Online catalog entries, shown locked until the Week 1 build.
nonisolated struct OnlineGameTeaser: Identifiable, Equatable {
    let id: String
    let title: String
    let emoji: String
    let tagline: String

    static let catalog: [OnlineGameTeaser] = [
        OnlineGameTeaser(id: "fibber", title: "Fibber", emoji: "🤥", tagline: "bluff your friends, find the truth"),
        OnlineGameTeaser(id: "decode", title: "Decode", emoji: "🕵️", tagline: "word grid, two teams, one trap"),
        OnlineGameTeaser(id: "theSnake", title: "The Snake", emoji: "🐍", tagline: "two traitors among you"),
        OnlineGameTeaser(id: "mostLikelyTo", title: "Most Likely To", emoji: "👉", tagline: "vote, reveal, pie of shame"),
        OnlineGameTeaser(id: "hotTakes", title: "Hot Takes", emoji: "🌶️", tagline: "pick a side, defend it"),
        OnlineGameTeaser(id: "storySpiral", title: "Story Spiral", emoji: "📖", tagline: "one sentence each, genre twists"),
        OnlineGameTeaser(id: "captionThis", title: "Caption This", emoji: "🖼️", tagline: "anonymous captions, group votes"),
        OnlineGameTeaser(id: "emojiCrimes", title: "Emoji Crimes", emoji: "🔤", tagline: "emoji-only clues, fastest guess wins"),
        OnlineGameTeaser(id: "doYouEvenKnowMe", title: "Do You Even Know Me", emoji: "🤨", tagline: "predict the subject's answers"),
        OnlineGameTeaser(id: "dailyDuel", title: "Daily Duel", emoji: "🔠", tagline: "one word a day, circle leaderboard"),
    ]
}
