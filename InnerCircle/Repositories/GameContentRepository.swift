import Foundation

// Loads the offline Game Shelf decks from the bundled seed-content.json.
// (When circles get custom cards in Week 1, this merges Firestore
// gameContent on top; the bundle stays the starter pack.)
final class GameContentRepository {
    private static var cachedGames: [OfflineGame]?

    func offlineGames() -> [OfflineGame] {
        if let cached = Self.cachedGames { return cached }
        guard let url = Bundle.main.url(forResource: "seed-content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        let games = Self.build(from: root)
        Self.cachedGames = games
        return games
    }

    // Raw string decks for the online games (prompts drawn at session start).
    func onlineDeck(_ key: String) -> [String] {
        guard let url = Bundle.main.url(forResource: "seed-content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        if let items = root[key] as? [String] { return items }
        return []
    }

    // Narrator lines etc. for The Snake.
    func snakeContent() -> (narrator: [String], missions: [String]) {
        guard let url = Bundle.main.url(forResource: "seed-content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let snake = root["snake_game"] as? [String: Any] else {
            return ([], [])
        }
        return (snake["narrator_lines"] as? [String] ?? [],
                snake["mission_flavors"] as? [String] ?? [])
    }

    private static func build(from root: [String: Any]) -> [OfflineGame] {
        func strings(_ key: String) -> [String] {
            root[key] as? [String] ?? []
        }

        let charades = OfflineGame(
            id: "dumbCharades", title: "Dumb Charades", emoji: "🎭",
            tagline: "act it out, no words, no mercy", colorway: "sunset",
            decks: [
                GameDeck(id: "bollywood", name: "Bollywood", cards: strings("charades_bollywood")),
                GameDeck(id: "hollywood", name: "Hollywood", cards: strings("charades_hollywood")),
                GameDeck(id: "songs", name: "Songs", cards: strings("charades_songs")),
                GameDeck(id: "impossible", name: "Impossible Mode", cards: strings("charades_impossible")),
            ]
        )

        let truthOrDare = OfflineGame(
            id: "truthOrDare", title: "Truth or Dare", emoji: "🎯",
            tagline: "three intensity levels, skip is always free", colorway: "bubblegum",
            decks: [
                GameDeck(id: "truthMild", name: "Truth · Mild", cards: strings("truth_mild")),
                GameDeck(id: "truthSpicy", name: "Truth · Spicy", cards: strings("truth_spicy")),
                GameDeck(id: "truthChaos", name: "Truth · Chaos", cards: strings("truth_chaos")),
                GameDeck(id: "dareMild", name: "Dare · Mild", cards: strings("dare_mild")),
                GameDeck(id: "dareSpicy", name: "Dare · Spicy", cards: strings("dare_spicy")),
                GameDeck(id: "dareChaos", name: "Dare · Chaos", cards: strings("dare_chaos")),
            ]
        )

        var kingsCupCards: [String] = []
        if let rules = root["kings_cup_rules"] as? [[String: String]] {
            kingsCupCards = rules.compactMap { rule in
                guard let card = rule["card"], let text = rule["rule"] else { return nil }
                return "\(card)\n\(text)"
            }
        }
        let kingsCup = OfflineGame(
            id: "kingsCup", title: "King's Cup", emoji: "👑",
            tagline: "card rules, zero proof mode included. drink responsibly", colorway: "mango",
            decks: [
                GameDeck(id: "rules", name: "The Rules", cards: kingsCupCards),
                GameDeck(id: "forfeits", name: "Zero Proof Forfeits", cards: strings("kings_cup_zero_proof_forfeits")),
            ]
        )

        let whisperDown = OfflineGame(
            id: "whisperDown", title: "Whisper Down", emoji: "🤫",
            tagline: "one player sees the question. chaos follows", colorway: "grape",
            decks: [GameDeck(id: "questions", name: "Questions", cards: strings("whisper_down"))]
        )

        var mafiaCards: [String] = []
        if let mafia = root["mafia_nights"] as? [String: Any] {
            if let roles = mafia["roles"] as? [[String: Any]] {
                mafiaCards += roles.compactMap { role in
                    guard let name = role["role"] as? String, let desc = role["desc"] as? String else { return nil }
                    return "\(name)\n\(desc)"
                }
            }
        }
        var mafiaScript: [String] = []
        if let mafia = root["mafia_nights"] as? [String: Any] {
            mafiaScript = mafia["narrator_script"] as? [String] ?? []
        }
        let mafiaNights = OfflineGame(
            id: "mafiaNights", title: "Mafia Nights", emoji: "🌃",
            tagline: "the app narrates, you betray", colorway: "sky",
            decks: [
                GameDeck(id: "roles", name: "Role Cards", cards: mafiaCards),
                GameDeck(id: "script", name: "Narrator Script", cards: mafiaScript),
            ]
        )

        var foreheadDecks: [GameDeck] = []
        if let decks = root["forehead_decks"] as? [String: [String]] {
            let names: [(String, String)] = [
                ("animals_doing_jobs", "Animals Doing Jobs"),
                ("aunty_phrases", "Aunty Phrases"),
                ("things_in_this_room", "Things In This Room"),
                ("actions", "Actions"),
            ]
            foreheadDecks = names.compactMap { key, name in
                guard let cards = decks[key] else { return nil }
                return GameDeck(id: key, name: name, cards: cards)
            }
        }
        let forehead = OfflineGame(
            id: "foreheadGame", title: "Forehead Game", emoji: "🫣",
            tagline: "phone on forehead, friends yell clues", colorway: "mint",
            decks: foreheadDecks
        )

        let twoTruths = OfflineGame(
            id: "twoTruthsAndASnake", title: "Two Truths and a Snake", emoji: "🐍",
            tagline: "themed rounds so it never stalls", colorway: "grape",
            decks: [GameDeck(id: "themes", name: "Round Themes", cards: strings("two_truths_themes"))]
        )

        let hotSeat = OfflineGame(
            id: "hotSeat", title: "Hot Seat", emoji: "🔥",
            tagline: "90 seconds, rapid fire, one veto allowed", colorway: "sunset",
            decks: [GameDeck(id: "questions", name: "Questions", cards: strings("hot_seat"))]
        )

        var huntDecks: [GameDeck] = []
        if let hunt = root["the_hunt"] as? [String: [String]] {
            let names: [(String, String)] = [
                ("house_party", "House Party"),
                ("outdoors", "Outdoors"),
                ("restaurant", "Restaurant"),
            ]
            huntDecks = names.compactMap { key, name in
                guard let cards = hunt[key] else { return nil }
                return GameDeck(id: key, name: name, cards: cards)
            }
        }
        let theHunt = OfflineGame(
            id: "theHunt", title: "The Hunt", emoji: "📸",
            tagline: "photo scavenger hunt, loot goes on the postcard", colorway: "mango",
            decks: huntDecks
        )

        let wyrIRL = OfflineGame(
            id: "wyrIRL", title: "Would You Rather: IRL", emoji: "🤝",
            tagline: "physical choices, live consequences", colorway: "sky",
            decks: [GameDeck(id: "cards", name: "Cards", cards: strings("wyr_irl"))]
        )

        return [charades, truthOrDare, kingsCup, whisperDown, mafiaNights,
                forehead, twoTruths, hotSeat, theHunt, wyrIRL]
    }
}
