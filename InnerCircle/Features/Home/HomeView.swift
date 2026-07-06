import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            Text(Copy.homeEmptyHangout)
                .foregroundStyle(.secondary)
                .navigationTitle("Home")
        }
    }
}
