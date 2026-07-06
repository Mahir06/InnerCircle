import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.phase {
            case .loading:
                SplashView()
            case .signedOut, .needsCircle:
                OnboardingView()
            case .ready:
                MainTabView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !appState.backendConnected {
                Text(Copy.offlineBackend)
                    .font(.caption2)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.yellow.opacity(0.25))
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("⭕️")
                .font(.system(size: 64))
            Text("Inner Circle")
                .font(.largeTitle.bold())
            Text("your digital headquarters for friendship")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
            HangoutsView()
                .tabItem { Label("Hangouts", systemImage: "calendar") }
            MailboxView()
                .tabItem { Label("Mailbox", systemImage: "envelope.fill") }
            CirclePageView()
                .tabItem { Label("Circle", systemImage: "person.3.fill") }
        }
    }
}

#Preview {
    RootView().environmentObject(AppState())
}
