import SwiftUI

// Runs right after signup: pick a name, an emoji, and a colorway for your ID Card.
struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppState

    @State private var name = ""
    @State private var emoji = "🙂"
    @State private var colorway = "sunset"
    @State private var tagline = ""
    @State private var busy = false
    @State private var errorMessage: String?

    private let emojiChoices = ["🙂", "😎", "🦖", "🐸", "🌞", "👽", "🍕", "🐼", "🔥", "🧃", "🎧", "🌵"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("make your ID Card")
                    .font(.title.bold())
                    .padding(.top, 32)
                Text("this is how the circle sees you. choose wisely")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // live ID card preview
                VStack(spacing: 8) {
                    Text(emoji).font(.system(size: 48))
                    Text(name.isEmpty ? "your name" : name)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(tagline.isEmpty ? "tagline goes here" : tagline)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Theme.colorway(colorway), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

                TextField("what do they call you?", text: $name)
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)

                TextField("tagline (optional flex)", text: $tagline)
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)

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
                .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    ForEach(Array(Theme.colorways.keys.sorted()), id: \.self) { key in
                        SwiftUI.Circle()
                            .fill(Theme.colorway(key))
                            .frame(width: 34, height: 34)
                            .overlay {
                                if key == colorway {
                                    SwiftUI.Circle().strokeBorder(.white, lineWidth: 3)
                                }
                            }
                            .onTapGesture { colorway = key }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    save()
                } label: {
                    Group {
                        if busy {
                            ProgressView().tint(.white)
                        } else {
                            Text("that's me")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
                }
                .disabled(busy || name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func save() {
        guard let uid = appState.authUid else { return }
        busy = true
        errorMessage = nil
        Task {
            do {
                var user = AppUser.new(displayName: name.trimmingCharacters(in: .whitespaces))
                user.idCard = IDCard(
                    color: colorway,
                    emoji: emoji,
                    tagline: tagline.isEmpty ? "new here, be nice" : tagline
                )
                try await appState.userRepo.createUser(user, uid: uid)
                // user doc listener flips the phase to needsCircle
            } catch {
                errorMessage = error.localizedDescription
            }
            busy = false
        }
    }
}
