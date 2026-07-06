import SwiftUI

// Story-style intro pages, then email auth.
struct OnboardingView: View {
    @State private var showAuth = false

    var body: some View {
        if showAuth {
            AuthFormView(onBack: { showAuth = false })
        } else {
            StoryPagesView(onDone: { showAuth = true })
        }
    }
}

private struct StoryPagesView: View {
    let onDone: () -> Void
    @State private var page = 0

    private let pages: [(emoji: String, title: String, line: String)] = [
        ("⭕️", "one circle. your people.", "no feeds, no followers, no strangers. just the group chat that matters"),
        ("📅", "plans that actually happen", "posters, RSVPs, potluck sign-ups. the plan stops dying in the chat"),
        ("💌", "memories that seal themselves", "after every hangout a postcard opens. 2 days to add your bit, then the envelope seals forever"),
    ]

    var body: some View {
        VStack {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 20) {
                        Text(pages[i].emoji).font(.system(size: 80))
                        Text(pages[i].title).font(.title.bold())
                            .multilineTextAlignment(.center)
                        Text(pages[i].line)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    onDone()
                }
            } label: {
                Text(page < pages.count - 1 ? "next" : "let's go")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)

            Button("skip the tour", action: onDone)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding(.vertical, 24)
    }
}

private struct AuthFormView: View {
    let onBack: () -> Void
    @EnvironmentObject var appState: AppState

    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var showForgot = false
    @State private var forgotSent = false

    var body: some View {
        VStack(spacing: 16) {
            Button(action: onBack) {
                Label("back", systemImage: "chevron.left")
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            Text("⭕️").font(.system(size: 56))
            Text(isSignUp ? "claim your spot" : "welcome back")
                .font(.title.bold())
            Text(isSignUp ? "one account, one circle, zero strangers" : Copy.lastSeen)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                SecureField("password", text: $password)
                    .padding()
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            if forgotSent {
                Text("reset link sent. go fish it out of your inbox")
                    .font(.footnote)
                    .foregroundStyle(.green)
            }

            Button {
                submit()
            } label: {
                Group {
                    if busy {
                        ProgressView().tint(.white)
                    } else {
                        Text(isSignUp ? "create account" : "sign in")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
            }
            .disabled(busy || email.isEmpty || password.isEmpty)

            HStack {
                Button(isSignUp ? "already in? sign in" : "new here? create account") {
                    isSignUp.toggle()
                    errorMessage = nil
                }
                .font(.footnote)
                if !isSignUp {
                    Spacer()
                    Button(Copy.authForgot) { showForgot = true }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(24)
        .alert("forgot your password?", isPresented: $showForgot) {
            Button("send reset link") { sendReset() }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("we'll email \(email.isEmpty ? "you" : email) a reset link. happens to the best of us")
        }
    }

    private func submit() {
        errorMessage = nil
        busy = true
        Task {
            do {
                if isSignUp {
                    _ = try await appState.authRepo.signUp(email: email, password: password)
                } else {
                    _ = try await appState.authRepo.signIn(email: email, password: password)
                }
                // AppState's auth listener takes it from here
            } catch {
                errorMessage = error.localizedDescription
            }
            busy = false
        }
    }

    private func sendReset() {
        guard !email.isEmpty else {
            errorMessage = "type your email first, then we can panic together"
            return
        }
        Task {
            do {
                try await appState.authRepo.sendPasswordReset(email: email)
                forgotSent = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
