import SwiftUI

// Every started hangout gets its own chat. When it's over, the AI scribe
// can press the whole conversation into the hangout's postcard.
struct HangoutChatView: View {
    let hangout: Hangout
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ChatViewModel()
    @State private var sealing = false

    var body: some View {
        ChatSurface(vm: vm)
            .navigationTitle(hangout.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if hangout.status == .done {
                        Button {
                            sealing = true
                            let resolve = resolver()
                            vm.sealStory(hangoutTitle: hangout.title, memberName: resolve)
                        } label: {
                            if sealing && !vm.storySealed {
                                ProgressView()
                            } else if vm.storySealed {
                                Label("in the postcard", systemImage: "checkmark.seal.fill")
                                    .labelStyle(.titleAndIcon)
                            } else {
                                Label("seal the story", systemImage: "wand.and.stars")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                        .disabled(sealing || vm.storySealed)
                    }
                }
            }
            .onAppear {
                if let circleId = appState.circle?.id, let uid = appState.authUid {
                    vm.start(circleId: circleId, userId: uid, hangoutId: hangout.id)
                }
            }
    }

    // Snapshot names on the main actor so the digest can run anywhere.
    private func resolver() -> (String) -> String {
        let names = Dictionary(uniqueKeysWithValues: appState.members.compactMap { member in
            member.id.map { ($0, member.displayName) }
        })
        return { names[$0] ?? "someone" }
    }
}
