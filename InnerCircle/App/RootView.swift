import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.phase {
            case .loading:
                SplashView()
            case .signedOut:
                OnboardingView()
            case .needsProfile:
                ProfileSetupView()
            case .needsCircle:
                CircleForkView()
            case .ready:
                MainTabView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !appState.backendConnected && !DemoContent.isActive {
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
    @StateObject private var router = TabRouter()

    var body: some View {
        TabView(selection: $router.selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag("home")
            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag("chat")
            HangoutsView()
                .tabItem { Label("Hangouts", systemImage: "calendar") }
                .tag("hangouts")
            MailboxView()
                .tabItem { Label("Mailbox", systemImage: "envelope.fill") }
                .tag("mailbox")
            CirclePageView()
                .tabItem { Label("Circle", systemImage: "person.3.fill") }
                .tag("circle")
        }
        .environmentObject(router)
    }
}

#Preview {
    RootView().environmentObject(AppState())
}
