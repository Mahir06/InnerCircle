import Foundation
import FirebaseFirestore

// Sparks: daily prompts. Firestore-first (sparks/ collection, seeded by
// Cloud Functions), with the bundled seed pack as offline fallback so
// spark drops always work.
final class SparkRepository {
    private var db: Firestore { FirebaseManager.shared.db }
    private var configured: Bool { FirebaseManager.shared.isConfigured }

    func todaySpark() async -> Spark? {
        if configured {
            let today = Self.dayString(Date())
            if let snapshot = try? await db.collection("sparks")
                .whereField("activeDate", isEqualTo: today)
                .limit(to: 1)
                .getDocuments(),
               let doc = snapshot.documents.first,
               let spark = try? doc.data(as: Spark.self) {
                return spark
            }
        }
        // deterministic per day so the whole circle sees the same one
        let pack = Self.localSparks()
        guard !pack.isEmpty else { return nil }
        let dayNumber = Int(Date().timeIntervalSince1970 / 86400)
        return pack[dayNumber % pack.count]
    }

    func randomSpark() -> Spark? {
        Self.localSparks().randomElement()
    }

    static func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - bundled seed pack

    private static var cached: [Spark]?

    private static func localSparks() -> [Spark] {
        if let cached { return cached }
        guard let url = Bundle.main.url(forResource: "seed-content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = root["sparks_daily"] as? [[String: String]] else {
            cached = []
            return []
        }
        let sparks = items.compactMap { item -> Spark? in
            guard let prompt = item["prompt"],
                  let kindRaw = item["kind"],
                  let kind = SparkKind(rawValue: kindRaw) else { return nil }
            return Spark(id: nil, prompt: prompt, kind: kind, activeDate: nil)
        }
        cached = sparks
        return sparks
    }
}
