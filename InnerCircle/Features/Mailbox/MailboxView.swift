import SwiftUI

struct MailboxView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = MailboxViewModel()
    @State private var layout: Layout = .stack
    @State private var selectedDate: Date?

    enum Layout: String, CaseIterable {
        case stack = "stack"
        case calendar = "calendar"
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.postcards.isEmpty {
                    VStack(spacing: 8) {
                        Text("📭").font(.system(size: 48))
                        Text(Copy.mailboxEmpty).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Picker("layout", selection: $layout) {
                                ForEach(Layout.allCases, id: \.self) { layout in
                                    Text(layout.rawValue).tag(layout)
                                }
                            }
                            .pickerStyle(.segmented)

                            if layout == .stack {
                                onThisDayCard
                                ForEach(vm.postcards) { postcard in
                                    NavigationLink(value: postcard.id ?? "") {
                                        PostcardCard(postcard: postcard)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                MailboxCalendar(vm: vm, selectedDate: $selectedDate)
                                if let selectedDate {
                                    let dayCards = vm.postcards(on: selectedDate)
                                    if dayCards.isEmpty {
                                        Text("nothing happened here. or did it?")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    ForEach(dayCards) { postcard in
                                        NavigationLink(value: postcard.id ?? "") {
                                            PostcardCard(postcard: postcard)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Mailbox")
            .navigationDestination(for: String.self) { postcardId in
                PostcardDetailView(postcardId: postcardId)
                    .environmentObject(vm)
            }
            .onAppear {
                if let circleId = appState.circle?.id, let uid = appState.authUid {
                    vm.start(circleId: circleId, userId: uid)
                }
            }
        }
    }

    @ViewBuilder
    private var onThisDayCard: some View {
        if let memory = vm.onThisDay {
            NavigationLink(value: memory.id ?? "") {
                HStack(spacing: 12) {
                    Text("🗓️").font(.system(size: 30))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("remember this?")
                            .font(.caption.bold())
                            .foregroundStyle(Theme.accent)
                        Text(memory.hangoutTitle ?? "a mystery memory")
                            .font(.subheadline.bold())
                        Text(memory.createdAt.formatted(date: .long, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "sparkles").foregroundStyle(.yellow)
                }
                .padding(14)
                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Postcard card

struct PostcardCard: View {
    let postcard: Postcard
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(postcard.isLockedCapsule ? "🔒" : "💌")
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(postcard.isLockedCapsule ? "Time Capsule" : (postcard.hangoutTitle ?? "untitled memory"))
                        .font(.headline)
                    Text(postcard.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                sealBadge
            }
            if !postcard.isLockedCapsule {
                HStack(spacing: 4) {
                    Text("\(postcard.blocks.count) block\(postcard.blocks.count == 1 ? "" : "s")")
                    Text("·")
                    Text("\(postcard.contributorIds.count) contributor\(postcard.contributorIds.count == 1 ? "" : "s")")
                    if let framedBy = postcard.framedBy {
                        Text("·")
                        Text("framed by \(appState.memberName(framedBy))")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else if let unlockAt = postcard.unlockAt {
                Text("unlocks \(unlockAt.formatted(date: .long, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var sealBadge: some View {
        if postcard.isSealed {
            Text("sealed ✉️")
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.green.opacity(0.15), in: Capsule())
                .foregroundStyle(.green)
        } else {
            Text(sealCountdown(postcard.sealsAt))
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.orange.opacity(0.15), in: Capsule())
                .foregroundStyle(.orange)
        }
    }
}

func sealCountdown(_ sealsAt: Date) -> String {
    let seconds = sealsAt.timeIntervalSinceNow
    if seconds <= 0 { return "sealing..." }
    let hours = Int(seconds / 3600)
    if hours >= 24 { return "seals in \(hours / 24)d \(hours % 24)h" }
    if hours >= 1 { return "seals in \(hours)h" }
    return "seals in \(max(1, Int(seconds / 60)))m"
}

// MARK: - Calendar

private struct MailboxCalendar: View {
    @ObservedObject var vm: MailboxViewModel
    @Binding var selectedDate: Date?
    @State private var displayedMonth = Calendar.current.startOfMonth(for: Date())

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Text("")
                }
                ForEach(daysInMonth, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: displayedMonth)!
                    let hasMemories = !vm.postcards(on: date).isEmpty
                    let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    VStack(spacing: 2) {
                        Text("\(day)")
                            .font(.footnote)
                            .frame(width: 30, height: 30)
                            .background(isSelected ? Theme.accent : .clear, in: SwiftUI.Circle())
                            .foregroundStyle(isSelected ? .white : .primary)
                        SwiftUI.Circle()
                            .fill(hasMemories ? Theme.accent : .clear)
                            .frame(width: 5, height: 5)
                    }
                    .onTapGesture { selectedDate = date }
                }
            }
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: displayedMonth)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private var daysInMonth: [Int] {
        Array(calendar.range(of: .day, in: .month, for: displayedMonth) ?? 1..<2)
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date))!
    }
}
