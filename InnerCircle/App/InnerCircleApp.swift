import SwiftUI

@main
struct InnerCircleApp: App {
    @StateObject private var appState: AppState

    init() {
        _ = FirebaseManager.shared   // configure Firebase before anything else
        Theme.registerFonts()
        _appState = StateObject(wrappedValue: AppState())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .tint(Theme.accent)
        }
    }
}
