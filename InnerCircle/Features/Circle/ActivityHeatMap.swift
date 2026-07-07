import SwiftUI

// GitHub-style contribution grid: the circle's last 20 weeks of life.
// Each cell = one day; intensity = hangouts + postcards that day.
struct ActivityHeatMap: View {
    let dates: [Date]

    private static let weeks = 20
    private let calendar = Calendar.current

    private var countsByDay: [Date: Int] {
        var counts: [Date: Int] = [:]
        for date in dates {
            counts[calendar.startOfDay(for: date), default: 0] += 1
        }
        return counts
    }

    var body: some View {
        let counts = countsByDay
        let today = calendar.startOfDay(for: Date())
        // grid columns are weeks, rows are weekdays, ending today
        let daysBack = Self.weeks * 7
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 3) {
                ForEach(0..<Self.weeks, id: \.self) { week in
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { day in
                            let offset = daysBack - 1 - (week * 7 + day)
                            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
                            cell(count: date > today ? -1 : (counts[date] ?? 0))
                        }
                    }
                }
            }
            HStack(spacing: 8) {
                Text("less").font(.system(size: 9)).foregroundStyle(.secondary)
                ForEach(0..<4) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(for: level))
                        .frame(width: 9, height: 9)
                }
                Text("more").font(.system(size: 9)).foregroundStyle(.secondary)
                Spacer()
                Text("\(dates.count) memories in \(Self.weeks) weeks")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func cell(count: Int) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(count < 0 ? Color.clear : color(for: min(count, 3)))
            .frame(width: 12, height: 12)
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 0: return Theme.card
        case 1: return Theme.accent.opacity(0.3)
        case 2: return Theme.accent.opacity(0.6)
        default: return Theme.accent
        }
    }
}
