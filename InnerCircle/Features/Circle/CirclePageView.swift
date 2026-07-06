import SwiftUI

struct CirclePageView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = CircleViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("stamps")
                        .font(.headline)
                    StampsGrid(stamps: vm.stamps)
                }
                .padding(16)
            }
            .navigationTitle(appState.circle?.name ?? "Circle")
            .onAppear {
                if let circleId = appState.circle?.id, let uid = appState.authUid {
                    vm.start(circleId: circleId, userId: uid)
                }
            }
        }
    }
}
