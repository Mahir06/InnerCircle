import SwiftUI

struct ChatView: View {
    var body: some View {
        NavigationStack {
            Text(Copy.chatEmpty)
                .foregroundStyle(.secondary)
                .navigationTitle(Copy.chatTitle)
        }
    }
}
