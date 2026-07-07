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
                PostcardCanvasView(postcardId: postcardId)
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

// MARK: - the envelope

// Skeuomorphic envelope: open flap with the collage peeking out while
// contributions are live, closed flap with a wax seal once it's sealed,
// padlock badge for time capsules.
struct PostcardCard: View {
    let postcard: Postcard
    @EnvironmentObject var appState: AppState

    private var envelopeColor: Color { Color(red: 0.94, green: 0.90, blue: 0.83) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // envelope body
                VStack(alignment: .leading, spacing: 5) {
                    Spacer(minLength: 30)
                    Text(postcard.isLockedCapsule ? "Time Capsule" : (postcard.hangoutTitle ?? "untitled memory"))
                        .font(Theme.display(17, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    // address lines
                    Text("to: \(appState.circle?.name ?? "the circle")")
                        .font(Theme.displayItalic(12))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                    Text(addressLine)
                        .font(.caption2)
                        .foregroundStyle(Theme.ink.opacity(0.45))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(envelopeColor, in: RoundedRectangle(cornerRadius: 10))

                // flap
                EnvelopeFlap(open: !postcard.isSealed)
                    .fill(postcard.isSealed ? envelopeColor.opacity(0.97) : Theme.paper)
                    .overlay(EnvelopeFlap(open: !postcard.isSealed).stroke(Theme.ink.opacity(0.12), lineWidth: 1))
                    .frame(height: 34)

                // wax seal or countdown chip
                if postcard.isLockedCapsule {
                    sealCircle("🔒")
                } else if postcard.isSealed {
                    sealCircle(appState.circle?.coverEmoji ?? "💌")
                } else {
                    Text(sealCountdown(postcard.sealsAt))
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.orange, in: Capsule())
                        .foregroundStyle(.white)
                        .offset(y: 20)
                }

                // postage corner
                Text("💌")
                    .font(.system(size: 13))
                    .padding(4)
                    .background(.white.opacity(0.8))
                    .overlay(Rectangle().strokeBorder(Theme.ink.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [2, 2])))
                    .rotationEffect(.degrees(4))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 12)
                    .offset(y: 40)
            }
            .shadow(color: .black.opacity(0.10), radius: 6, y: 3)

            HStack(spacing: 4) {
                if postcard.isLockedCapsule, let unlockAt = postcard.unlockAt {
                    Text("unlocks \(unlockAt.formatted(date: .long, time: .omitted))")
                } else {
                    Text("\(postcard.blocks.count) thing\(postcard.blocks.count == 1 ? "" : "s") on the collage")
                    Text("·")
                    Text("\(postcard.contributorIds.count) hands")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 6)
        }
        .padding(.bottom, 4)
    }

    private var addressLine: String {
        postcard.createdAt.formatted(date: .long, time: .omitted)
    }

    private func sealCircle(_ emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 16))
            .frame(width: 36, height: 36)
            .background(
                SwiftUI.Circle()
                    .fill(LinearGradient(colors: [Theme.accent, Theme.accentDeep],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(SwiftUI.Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1.5))
            .shadow(color: Theme.accent.opacity(0.4), radius: 3, y: 2)
            .offset(y: 16)
    }
}

// Triangle flap: points down when sealed, folded up (out of the way) when open.
private struct EnvelopeFlap: Shape {
    let open: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if open {
            // open flap: a shallow trapezoid rising above the envelope
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY - 6))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            // closed flap: triangle folded down over the body
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        }
        path.closeSubpath()
        return path
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
