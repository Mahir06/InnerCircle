import SwiftUI

struct HangoutsView: View {
    var body: some View {
        NavigationStack {
            Text(Copy.hangoutsEmpty)
                .foregroundStyle(.secondary)
                .navigationTitle("Hangouts")
        }
    }
}
