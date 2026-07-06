import SwiftUI

struct MailboxView: View {
    var body: some View {
        NavigationStack {
            Text(Copy.mailboxEmpty)
                .foregroundStyle(.secondary)
                .navigationTitle("Mailbox")
        }
    }
}
