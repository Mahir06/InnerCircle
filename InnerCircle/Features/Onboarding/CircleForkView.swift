import SwiftUI

// The fork after profile setup: start a circle, or join one with a Group Ticket.
struct CircleForkView: View {
    @EnvironmentObject var appState: AppState
    @State private var route: Route?

    enum Route: Identifiable {
        case create, join
        var id: Int { self == .create ? 0 : 1 }
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("⭕️").font(.system(size: 64))
            Text("find your people")
                .font(.title.bold())
            Text("one circle per human. make it count")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                ForkCard(
                    emoji: "🏗️",
                    title: "start a circle",
                    line: "be the founder. you get a shareable Group Ticket"
                ) { route = .create }
                ForkCard(
                    emoji: "🎟️",
                    title: "i have a Group Ticket",
                    line: "someone sent you a 6-character code? in you go"
                ) { route = .join }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer()
            Button("sign out") { appState.signOut() }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
        }
        .sheet(item: $route) { route in
            switch route {
            case .create: CreateCircleSheet()
            case .join: JoinCircleSheet()
            }
        }
    }
}

private struct ForkCard: View {
    let emoji: String
    let title: String
    let line: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji).font(.system(size: 36))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(line).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding()
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct CreateCircleSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var coverEmoji = "🌀"
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var createdCircle: FriendCircle?

    private let emojiChoices = ["🌀", "🔥", "🌈", "🛸", "🍜", "🏝️", "🎪", "⚡️", "🐙", "🎮", "🧿", "🚀"]

    var body: some View {
        NavigationStack {
            if let circle = createdCircle {
                // ticket reveal
                VStack(spacing: 18) {
                    Spacer()
                    Text(circle.coverEmoji).font(.system(size: 64))
                    Text("\(circle.name) exists!").font(.title2.bold())
                    Text("here's your Group Ticket. send it to your people")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(circle.code)
                        .font(.system(size: 44, weight: .heavy, design: .monospaced))
                        .kerning(6)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 28)
                        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 16))
                    ShareLink(item: "you're invited to \(circle.name) on Inner Circle 🎟️ your Group Ticket: \(circle.code)") {
                        Label("share the ticket", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 24)
                    Button("enter the clubhouse") { dismiss() }
                        .font(.footnote)
                    Spacer()
                }
            } else {
                VStack(spacing: 18) {
                    TextField("circle name (the group chat name, but permanent)", text: $name)
                        .padding()
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojiChoices, id: \.self) { choice in
                            Text(choice)
                                .font(.system(size: 30))
                                .padding(6)
                                .background(choice == coverEmoji ? Theme.accentSoft : .clear,
                                            in: RoundedRectangle(cornerRadius: 10))
                                .onTapGesture { coverEmoji = choice }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage).font(.footnote).foregroundStyle(.red)
                    }

                    Button {
                        create()
                    } label: {
                        Group {
                            if busy { ProgressView().tint(.white) } else { Text("found the circle") }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                    }
                    .disabled(busy || name.trimmingCharacters(in: .whitespaces).isEmpty)
                    Spacer()
                }
                .padding(24)
                .navigationTitle("start a circle")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func create() {
        guard let uid = appState.authUid else { return }
        busy = true
        errorMessage = nil
        Task {
            do {
                createdCircle = try await appState.circleRepo.createCircle(
                    name: name.trimmingCharacters(in: .whitespaces),
                    coverEmoji: coverEmoji,
                    creatorId: uid
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            busy = false
        }
    }
}

private struct JoinCircleSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var busy = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("🎟️").font(.system(size: 56)).padding(.top, 24)
                Text("punch your ticket")
                    .font(.title2.bold())
                Text("6 characters, no pressure")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("GROUP TICKET", text: $code)
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .kerning(4)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    .onChange(of: code) { _, new in
                        code = String(new.uppercased().prefix(6))
                    }

                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                }

                Button {
                    join()
                } label: {
                    Group {
                        if busy { ProgressView().tint(.white) } else { Text("join the circle") }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
                }
                .disabled(busy || code.count != 6)
                Spacer()
            }
            .padding(24)
        }
    }

    private func join() {
        guard let uid = appState.authUid else { return }
        busy = true
        errorMessage = nil
        Task {
            do {
                _ = try await appState.circleRepo.joinCircle(code: code, userId: uid)
                dismiss()
                // circle listener flips the phase to ready
            } catch {
                errorMessage = error.localizedDescription
            }
            busy = false
        }
    }
}
