import Foundation

// Turns a pile of messages into a short story in the app's voice.
// Uses the Claude API when an Anthropic key is present in Secrets.plist
// (gitignored); otherwise falls back to a local extractive digest so the
// feature always works.
final class AISummaryService {

    static var anthropicKey: String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }
        let key = dict["AnthropicAPIKey"] as? String
        return (key?.isEmpty ?? true) ? nil : key
    }

    // memberName resolves userIds to display names.
    static func digest(messages: [Message], title: String, memberName: (String) -> String) async -> String {
        let transcript = transcript(of: messages, memberName: memberName)
        if let key = anthropicKey, !transcript.isEmpty {
            if let summary = await claudeDigest(transcript: transcript, title: title, key: key) {
                return summary
            }
        }
        return localDigest(messages: messages, title: title, memberName: memberName)
    }

    // MARK: - Claude backend

    private static func claudeDigest(transcript: String, title: String, key: String) async -> String? {
        let prompt = """
        Summarize this friend-group chat from a hangout called "\(title)" in 3-4 sentences. \
        Voice: warm, playful, Gen Z, lowercase, never corporate, no m-dashes. \
        Capture the funniest moments and any decisions made. Refer to people by name.

        \(transcript)
        """
        let body: [String: Any] = [
            "model": "claude-sonnet-5",
            "max_tokens": 400,
            "messages": [["role": "user", "content": prompt]],
        ]
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            return nil
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func transcript(of messages: [Message], memberName: (String) -> String) -> String {
        messages.suffix(80).compactMap { message -> String? in
            let name = message.senderId == "system" ? "(system)" : memberName(message.senderId)
            switch message.type {
            case .text, .system:
                guard let text = message.text else { return nil }
                return "\(name): \(text)"
            case .poll:
                guard let poll = message.poll else { return nil }
                let winner = poll.options.max { $0.voterIds.count < $1.voterIds.count }
                return "\(name) polled \"\(poll.question)\" and \"\(winner?.label ?? "?")\" won"
            case .spark:
                guard let spark = message.spark else { return nil }
                let answers = spark.answers.map { "\(memberName($0.key)): \($0.value)" }.joined(separator: "; ")
                return "spark \"\(spark.prompt)\" answers: \(answers)"
            case .hangoutInvite:
                return "\(name) dropped a hangout invite: \(message.text ?? "")"
            case .gameInvite:
                return "\(name) opened a game table: \(message.text ?? "")"
            }
        }.joined(separator: "\n")
    }

    // MARK: - local fallback

    private static func localDigest(messages: [Message], title: String, memberName: (String) -> String) -> String {
        let real = messages.filter { $0.type != .system }
        guard !real.isEmpty else {
            return "\(title) happened. the chat stayed suspiciously quiet. what happens at the hangout stays at the hangout"
        }
        let people = Set(real.map(\.senderId)).map { memberName($0) }.sorted()
        var lines: [String] = []
        lines.append("\(title): \(real.count) messages of chaos from \(people.joined(separator: ", "))")

        // the crowd favorite: most-reacted message
        let topReacted = real
            .filter { !($0.reactions ?? [:]).isEmpty }
            .max { a, b in
                (a.reactions ?? [:]).values.map(\.count).reduce(0, +) <
                (b.reactions ?? [:]).values.map(\.count).reduce(0, +)
            }
        if let topReacted, let text = topReacted.text {
            lines.append("crowd favorite: \"\(text)\" (\(memberName(topReacted.senderId)))")
        }

        // poll verdicts
        for message in real where message.type == .poll {
            if let poll = message.poll,
               let winner = poll.options.max(by: { $0.voterIds.count < $1.voterIds.count }),
               winner.voterIds.count > 0 {
                lines.append("the circle has spoken: \"\(winner.label)\" won \"\(poll.question)\"")
            }
        }

        // spark answers count
        let sparkAnswers = real.compactMap(\.spark).map { $0.answers.count }.reduce(0, +)
        if sparkAnswers > 0 {
            lines.append("\(sparkAnswers) spark answer\(sparkAnswers == 1 ? "" : "s") on the record")
        }

        return lines.prefix(4).joined(separator: "\n")
    }
}
