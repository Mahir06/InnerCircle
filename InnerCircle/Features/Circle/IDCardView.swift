import SwiftUI

// The ID Card as a physical object: lanyard hole, holo gradient, barcode.
// Tap to flip it over for the stats side. Yours is editable.
struct IDCardView: View {
    let member: AppUser
    let stamps: [Stamp]
    let circleName: String

    @EnvironmentObject var appState: AppState
    @State private var flipped = false
    @State private var showEditor = false

    private var isMe: Bool { member.id == appState.authUid }
    private var cardColor: Color { Theme.colorway(member.idCard.color) }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                cardBack.opacity(flipped ? 1 : 0)
                    .rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                cardFront.opacity(flipped ? 0 : 1)
                    .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            }
            .animation(.spring(duration: 0.6), value: flipped)
            .onTapGesture { flipped.toggle() }

            Text("tap the card to flip it")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if isMe {
                Button("edit my card") { showEditor = true }
                    .buttonStyle(ChunkyButtonStyle())
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
        .navigationTitle("ID Card")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditor) {
            IDCardEditorSheet(idCard: member.idCard) { updated in
                if let uid = member.id {
                    Task { try? await appState.userRepo.updateIDCard(updated, uid: uid) }
                }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: front

    private var cardFront: some View {
        VStack(spacing: 0) {
            // lanyard punch hole
            Capsule()
                .fill(.black.opacity(0.25))
                .frame(width: 44, height: 9)
                .padding(.top, 14)

            Text(member.idCard.emoji)
                .font(.system(size: 64))
                .frame(width: 110, height: 110)
                .background(.white.opacity(0.25), in: SwiftUI.Circle())
                .overlay(SwiftUI.Circle().strokeBorder(.white.opacity(0.6), lineWidth: 3))
                .padding(.top, 18)

            Text(member.displayName)
                .font(Theme.display(28, weight: .black))
                .foregroundStyle(.white)
                .padding(.top, 12)
            Text(member.idCard.tagline)
                .font(Theme.displayItalic(14))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)

            Spacer()

            VStack(spacing: 3) {
                Text("INNER CIRCLE · \(circleName.uppercased())")
                    .font(.system(size: 10, weight: .heavy))
                    .kerning(1.5)
                    .foregroundStyle(.white.opacity(0.85))
                Text("member since \(member.createdAt.formatted(.dateTime.month(.abbreviated).year()))")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
            }

            barcode
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
        }
        .frame(width: 290, height: 430)
        .background(
            LinearGradient(
                colors: [cardColor, cardColor.opacity(0.75), Theme.accentDeep.opacity(0.9)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26)
        )
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(.white.opacity(0.25), lineWidth: 1))
        .shadow(color: cardColor.opacity(0.45), radius: 18, y: 10)
    }

    // MARK: back

    private var cardBack: some View {
        VStack(spacing: 14) {
            Rectangle()
                .fill(.black.opacity(0.8))
                .frame(height: 44)
                .padding(.top, 22)

            Text("stats on file")
                .font(Theme.heading)
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                backRow("🏅", "stamps earned", "\(stamps.count)")
                backRow("🎨", "colorway", member.idCard.color)
                if let status = member.status {
                    backRow(status.emoji, "current status", status.text)
                }
                ForEach(stamps.prefix(4)) { stamp in
                    backRow(stamp.kind.emoji, stamp.kind.title,
                            stamp.awardedAt.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Text("if found, return to the group chat")
                .font(.system(size: 9))
                .italic()
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 18)
        }
        .frame(width: 290, height: 430)
        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
    }

    private func backRow(_ emoji: String, _ label: String, _ value: String) -> some View {
        HStack {
            Text(emoji).font(.footnote)
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value).font(.caption.bold()).foregroundStyle(.white)
        }
    }

    // fake barcode built from the user's id characters
    private var barcode: some View {
        HStack(spacing: 1.5) {
            ForEach(Array((member.id ?? "innercircle").prefix(24).enumerated()), id: \.offset) { _, char in
                Rectangle()
                    .fill(.white.opacity(0.9))
                    .frame(width: char.isNumber ? 3 : 1.5, height: 30)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - editor

private struct IDCardEditorSheet: View {
    let idCard: IDCard
    let onSave: (IDCard) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var emoji: String
    @State private var color: String
    @State private var tagline: String

    private let emojiChoices = ["🙂", "😎", "🦖", "🐸", "🌞", "👽", "🍕", "🐼", "🔥", "🧃", "🎧", "🌵"]

    init(idCard: IDCard, onSave: @escaping (IDCard) -> Void) {
        self.idCard = idCard
        self.onSave = onSave
        _emoji = State(initialValue: idCard.emoji)
        _color = State(initialValue: idCard.color)
        _tagline = State(initialValue: idCard.tagline)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("face of the card") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojiChoices, id: \.self) { choice in
                            Text(choice)
                                .font(.system(size: 30))
                                .padding(6)
                                .background(choice == emoji ? Theme.accentSoft : .clear,
                                            in: RoundedRectangle(cornerRadius: 10))
                                .onTapGesture { emoji = choice }
                        }
                    }
                }
                Section("colorway") {
                    HStack(spacing: 12) {
                        ForEach(Array(Theme.colorways.keys.sorted()), id: \.self) { key in
                            SwiftUI.Circle()
                                .fill(Theme.colorway(key))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if key == color {
                                        SwiftUI.Circle().strokeBorder(.white, lineWidth: 3)
                                    }
                                }
                                .onTapGesture { color = key }
                        }
                    }
                }
                Section("tagline") {
                    TextField("your one-liner", text: $tagline)
                }
            }
            .navigationTitle("card editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        onSave(IDCard(color: color, emoji: emoji, tagline: tagline))
                        dismiss()
                    }
                }
            }
        }
    }
}
