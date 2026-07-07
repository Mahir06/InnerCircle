import SwiftUI
import PhotosUI
import UIKit

struct PostcardDetailView: View {
    let postcardId: String
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: MailboxViewModel

    @State private var newNote = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var showCapsulePicker = false
    @State private var showBadgePicker = false
    @State private var capsuleDate = Date().addingTimeInterval(30 * 86400)

    private let stickers = [
        "💖", "😂", "🔥", "🌟", "🫶", "🎉", "🍕", "🌈", "👑", "🦖",
        "😭", "💀", "🥹", "🤌", "🫠", "🎧", "🏆", "🍜", "🌊", "📸",
        "🪩", "🧿", "🚗", "🌙",
    ]

    var body: some View {
        if let postcard = vm.postcard(postcardId) {
            if postcard.isLockedCapsule {
                lockedView(postcard)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        header(postcard)
                        blocksSection(postcard)
                        if !postcard.isSealed {
                            addBar(postcard)
                            capsuleSection(postcard)
                        }
                        footer(postcard)
                    }
                    .padding(16)
                }
                .navigationTitle(postcard.hangoutTitle ?? "postcard")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { vm.loadHangoutStamps(for: postcard) }
                .onChange(of: photoItem) { _, item in
                    guard let item else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            vm.addPhotoBlock(data, to: postcard)
                        }
                        photoItem = nil
                    }
                }
                .sheet(isPresented: $showBadgePicker) {
                    BadgePickerSheet(stamps: vm.hangoutStamps) { stamp in
                        vm.addBadgeBlock(stamp, to: postcard)
                    }
                    .presentationDetents([.medium])
                }
            }
        } else {
            Text("this postcard got lost in the mail")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: locked capsule

    private func lockedView(_ postcard: Postcard) -> some View {
        VStack(spacing: 14) {
            Text("🔒").font(.system(size: 64))
            Text("Time Capsule").font(.title2.bold())
            if let unlockAt = postcard.unlockAt {
                Text("this memory unlocks \(unlockAt.formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("no peeking. we're serious")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: header

    private func header(_ postcard: Postcard) -> some View {
        VStack(spacing: 8) {
            if postcard.isSealed {
                Label(Copy.postcardSealed, systemImage: "envelope.fill")
                    .font(.footnote.bold())
                    .foregroundStyle(.green)
            } else {
                VStack(spacing: 4) {
                    Label(sealCountdown(postcard.sealsAt), systemImage: "hourglass")
                        .font(.footnote.bold())
                        .foregroundStyle(.orange)
                    Text(Copy.postcardSealing)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            Text(postcard.createdAt.formatted(date: .complete, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: blocks

    @ViewBuilder
    private func blocksSection(_ postcard: Postcard) -> some View {
        if postcard.blocks.isEmpty {
            Text("empty postcard. add the first memory before it seals")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 20)
        } else {
            ForEach(postcard.blocks.sorted { $0.position < $1.position }) { block in
                blockView(block)
                    .contextMenu {
                        if block.authorId == appState.authUid && !postcard.isSealed {
                            Button(role: .destructive) {
                                vm.deleteBlock(block, from: postcard)
                            } label: {
                                Label("take it back", systemImage: "trash")
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: PostcardBlock) -> some View {
        switch block.type {
        case .text:
            VStack(alignment: .leading, spacing: 6) {
                Text(block.content)
                    .font(.body)
                Text("- \(appState.memberName(block.authorId))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 14))
        case .photo:
            VStack(alignment: .leading, spacing: 4) {
                photoContent(block)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text("📸 \(appState.memberName(block.authorId))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .sticker:
            Text(block.content)
                .font(.system(size: 54))
                .frame(maxWidth: .infinity)
        case .aiSummary:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wand.and.stars").foregroundStyle(Theme.accent)
                    Text("the scribe's version").font(.caption.bold()).foregroundStyle(.secondary)
                }
                Text(block.content).font(.callout.italic())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1.5))
        case .badge:
            // content: "<stampKind>|<userId>"
            let parts = block.content.split(separator: "|").map(String.init)
            let kind = parts.first.flatMap { StampKind(rawValue: $0) }
            VStack(spacing: 4) {
                Text(kind?.emoji ?? "🏅").font(.system(size: 40))
                Text(kind?.title ?? "mystery badge").font(.caption.bold())
                if parts.count > 1 {
                    Text("earned by \(appState.memberName(parts[1]))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // Photos are either "media:<id>" docs in Firestore (free plan) or a
    // Storage URL (Blaze, later).
    @ViewBuilder
    private func photoContent(_ block: PostcardBlock) -> some View {
        if block.content.hasPrefix("media:") {
            let mediaId = String(block.content.dropFirst("media:".count))
            if let data = vm.media[mediaId], let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .onAppear { vm.loadMedia(mediaId: mediaId, postcardId: postcardId) }
            }
        } else {
            AsyncImage(url: URL(string: block.content)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Label("photo went missing", systemImage: "photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                default:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }
            }
        }
    }

    // MARK: add bar

    private func addBar(_ postcard: Postcard) -> some View {
        VStack(spacing: 10) {
            HStack {
                TextField("add a note to the postcard...", text: $newNote, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(10)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                Button("add") {
                    vm.addTextBlock(newNote, to: postcard)
                    newNote = ""
                }
                .font(.subheadline.bold())
                .disabled(newNote.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            HStack {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("photo", systemImage: "photo.badge.plus")
                        .font(.caption.bold())
                }
                Button {
                    showBadgePicker = true
                } label: {
                    Label("badge", systemImage: "medal.fill")
                        .font(.caption.bold())
                }
                .disabled(vm.hangoutStamps.isEmpty)
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(stickers, id: \.self) { sticker in
                            Button {
                                vm.addStickerBlock(sticker, to: postcard)
                            } label: {
                                Text(sticker).font(.title3)
                            }
                        }
                    }
                }
            }
            if let error = vm.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(Theme.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: time capsule

    private func capsuleSection(_ postcard: Postcard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { postcard.unlockAt != nil },
                set: { on in
                    if on {
                        showCapsulePicker = true
                    } else {
                        vm.setTimeCapsule(postcard, unlockAt: nil)
                    }
                }
            )) {
                Label("make it a Time Capsule", systemImage: "lock.badge.clock")
                    .font(.subheadline)
            }
            if let unlockAt = postcard.unlockAt {
                Text("locks when sealed, unlocks \(unlockAt.formatted(date: .long, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if showCapsulePicker {
                DatePicker("unlock date", selection: $capsuleDate, in: Date().addingTimeInterval(86400)..., displayedComponents: .date)
                Button("lock it in") {
                    vm.setTimeCapsule(postcard, unlockAt: capsuleDate)
                    showCapsulePicker = false
                }
                .font(.caption.bold())
            }
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: badge picker

    private struct BadgePickerSheet: View {
        let stamps: [Stamp]
        let onPick: (Stamp) -> Void
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject var appState: AppState

        var body: some View {
            NavigationStack {
                List(stamps) { stamp in
                    Button {
                        onPick(stamp)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text(stamp.kind.emoji).font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stamp.kind.title).font(.subheadline.bold())
                                Text("earned by \(appState.memberName(stamp.userId))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .navigationTitle("frame a badge")
                .navigationBarTitleDisplayMode(.inline)
                .overlay {
                    if stamps.isEmpty {
                        Text("no badges from this hangout")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: footer

    private func footer(_ postcard: Postcard) -> some View {
        VStack(spacing: 4) {
            Text("contributors: \(postcard.contributorIds.map { appState.memberName($0) }.joined(separator: ", "))")
            if let framedBy = postcard.framedBy {
                Text("framed by \(appState.memberName(framedBy))")
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }
}
