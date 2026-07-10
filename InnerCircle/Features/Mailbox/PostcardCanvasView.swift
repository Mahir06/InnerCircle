import SwiftUI
import PhotosUI
import UIKit

// The postcard as a collaborative collage table: a paper canvas where
// everyone tosses on photos, notes, stickers, doodles, and badges, drags
// them around, and when the window closes the whole thing goes into an
// envelope. Skeuomorphic on purpose: stamp corner, postmark, paper grain.
struct PostcardCanvasView: View {
    let postcardId: String
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var vm: MailboxViewModel

    @State private var selectedBlockId: String?
    @State private var draft = CGSize.zero                 // live drag offset for selected
    @State private var showNoteSheet = false
    @State private var showStickerSheet = false
    @State private var showBadgePicker = false
    @State private var showCapsulePicker = false
    @State private var doodling = false
    @State private var photoItem: PhotosPickerItem?
    @State private var capsuleDate = Date().addingTimeInterval(30 * 86400)

    var body: some View {
        if let postcard = vm.postcard(postcardId) {
            if postcard.isLockedCapsule {
                lockedView(postcard)
            } else {
                VStack(spacing: 0) {
                    statusBar(postcard)
                    GeometryReader { geo in
                        canvas(postcard, size: geo.size)
                    }
                    .aspectRatio(0.72, contentMode: .fit)
                    .padding(.horizontal, 14)
                    if !postcard.isSealed {
                        toolBar(postcard)
                    }
                    footer(postcard)
                }
                .background(Theme.background)
                .navigationTitle(postcard.hangoutTitle ?? "postcard")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if !postcard.isSealed {
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                Button {
                                    showCapsulePicker = true
                                } label: {
                                    Label(postcard.unlockAt == nil ? "make it a Time Capsule" : "change unlock date",
                                          systemImage: "lock.badge.clock")
                                }
                                if postcard.unlockAt != nil {
                                    Button(role: .destructive) {
                                        vm.setTimeCapsule(postcard, unlockAt: nil)
                                    } label: {
                                        Label("remove the lock", systemImage: "lock.open")
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
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
                .sheet(isPresented: $showNoteSheet) {
                    NoteSheet { text in vm.addTextBlock(text, to: postcard) }
                        .presentationDetents([.height(220)])
                }
                .sheet(isPresented: $showStickerSheet) {
                    StickerSheet { sticker in vm.addStickerBlock(sticker, to: postcard) }
                        .presentationDetents([.height(300)])
                }
                .sheet(isPresented: $showBadgePicker) {
                    BadgePickerSheet(stamps: vm.hangoutStamps) { stamp in
                        vm.addBadgeBlock(stamp, to: postcard)
                    }
                    .presentationDetents([.medium])
                }
                .sheet(isPresented: $showCapsulePicker) {
                    CapsuleSheet(date: $capsuleDate) {
                        vm.setTimeCapsule(postcard, unlockAt: capsuleDate)
                    }
                    .presentationDetents([.height(320)])
                }
                .fullScreenCover(isPresented: $doodling) {
                    DoodleView { encoded in
                        vm.addDoodleBlock(encoded, to: postcard)
                    }
                }
            }
        } else {
            Text("this postcard got lost in the mail")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: status strip

    private func statusBar(_ postcard: Postcard) -> some View {
        HStack {
            if postcard.isSealed {
                Label(Copy.postcardSealed, systemImage: "envelope.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            } else {
                Label(sealCountdown(postcard.sealsAt), systemImage: "hourglass")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                if postcard.unlockAt != nil {
                    Label("capsule", systemImage: "lock.badge.clock")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.accent)
                }
            }
            Spacer()
            if let error = vm.errorMessage {
                Text(error).font(.caption2).foregroundStyle(.red).lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: the canvas

    private func canvas(_ postcard: Postcard, size: CGSize) -> some View {
        ZStack {
            paper(postcard, size: size)

            ForEach(sortedBlocks(postcard)) { block in
                elementView(block, postcard: postcard, size: size)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contentShape(Rectangle())
        .onTapGesture { selectedBlockId = nil }
    }

    private func sortedBlocks(_ postcard: Postcard) -> [PostcardBlock] {
        postcard.blocks.sorted { ($0.z ?? $0.position) < ($1.z ?? $1.position) }
    }

    // paper texture + skeuomorphic postcard furniture
    private func paper(_ postcard: Postcard, size: CGSize) -> some View {
        ZStack {
            Theme.paper
            // faint ruled lines like the back of a real postcard
            VStack(spacing: size.height / 12) {
                ForEach(0..<6, id: \.self) { _ in
                    Rectangle().fill(Theme.ink.opacity(0.05)).frame(height: 1)
                }
            }
            .padding(.horizontal, 24)
            // stamp corner
            VStack(spacing: 2) {
                Text(appState.circle?.coverEmoji ?? "💌")
                    .font(.system(size: 26))
                Text("IC MAIL").font(.system(size: 7, weight: .heavy)).kerning(1)
            }
            .frame(width: 54, height: 64)
            .background(.white)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
            )
            .rotationEffect(.degrees(3))
            .position(x: size.width - 46, y: 48)
            // postmark
            SwiftUI.Circle()
                .strokeBorder(Theme.ink.opacity(0.18), lineWidth: 1.5)
                .frame(width: 58, height: 58)
                .overlay(
                    Text(postcard.createdAt.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Theme.ink.opacity(0.3))
                        .rotationEffect(.degrees(-12))
                )
                .position(x: size.width - 96, y: 58)
        }
    }

    // MARK: elements

    @ViewBuilder
    private func elementView(_ block: PostcardBlock, postcard: Postcard, size: CGSize) -> some View {
        let isSelected = selectedBlockId == block.id
        let baseX = (block.x ?? scatterX(block)) * size.width
        let baseY = (block.y ?? scatterY(block)) * size.height

        elementContent(block, size: size)
            .scaleEffect(block.scale ?? 1)
            .rotationEffect(.degrees(block.rotation ?? 0))
            .overlay {
                if isSelected && !postcard.isSealed {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Theme.accent, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        .padding(-6)
                }
            }
            .position(x: baseX + (isSelected ? draft.width : 0),
                      y: baseY + (isSelected ? draft.height : 0))
            .gesture(postcard.isSealed ? nil : dragGesture(block, postcard: postcard, size: size))
            .onTapGesture {
                guard !postcard.isSealed else { return }
                selectedBlockId = block.id
            }
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

    private func dragGesture(_ block: PostcardBlock, postcard: Postcard, size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                selectedBlockId = block.id
                draft = value.translation
            }
            .onEnded { value in
                draft = .zero
                let newX = min(max(((block.x ?? scatterX(block)) * size.width + value.translation.width) / size.width, 0.05), 0.95)
                let newY = min(max(((block.y ?? scatterY(block)) * size.height + value.translation.height) / size.height, 0.05), 0.95)
                vm.updatePlacement(block, in: postcard,
                                   x: newX, y: newY,
                                   rotation: block.rotation ?? 0,
                                   scale: block.scale ?? 1,
                                   z: maxZ(postcard) + 1)
            }
    }

    private func maxZ(_ postcard: Postcard) -> Int {
        postcard.blocks.compactMap(\.z).max() ?? postcard.blocks.count
    }

    // legacy blocks without coordinates get a stable scatter from their id
    private func scatterX(_ block: PostcardBlock) -> Double {
        0.25 + Double(abs(block.id.hashValue % 50)) / 100.0
    }
    private func scatterY(_ block: PostcardBlock) -> Double {
        0.2 + Double(abs((block.id.hashValue / 7) % 55)) / 100.0
    }

    @ViewBuilder
    private func elementContent(_ block: PostcardBlock, size: CGSize) -> some View {
        switch block.type {
        case .text:
            Text(block.content)
                .font(Theme.displayItalic(14))
                .foregroundStyle(Theme.ink)
                .padding(10)
                .frame(maxWidth: size.width * 0.5)
                .background(.white, in: RoundedRectangle(cornerRadius: 4))
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
        case .photo:
            photoContent(block)
                .frame(maxWidth: size.width * 0.48, maxHeight: size.height * 0.4)
                .padding(6)
                .background(.white)                      // polaroid frame
                .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
        case .sticker:
            Text(block.content)
                .font(.system(size: 46))
                .shadow(color: .black.opacity(0.15), radius: 2, y: 2)
        case .badge:
            badgeContent(block)
        case .aiSummary:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "wand.and.stars").font(.caption2)
                    Text("the scribe").font(.system(size: 9, weight: .heavy))
                }
                .foregroundStyle(Theme.accent)
                Text(block.content)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.ink)
            }
            .padding(10)
            .frame(maxWidth: size.width * 0.6)
            .background(.white, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.accent.opacity(0.4), lineWidth: 1))
            .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
        case .doodle:
            DoodleShape(encoded: block.content)
                .frame(width: size.width * 0.5, height: size.height * 0.35)
        }
    }

    @ViewBuilder
    private func photoContent(_ block: PostcardBlock) -> some View {
        if block.content.hasPrefix("media:") {
            let mediaId = String(block.content.dropFirst("media:".count))
            if let data = vm.media[mediaId], let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                ProgressView()
                    .frame(width: 80, height: 80)
                    .onAppear { vm.loadMedia(mediaId: mediaId, postcardId: postcardId) }
            }
        } else {
            AsyncImage(url: URL(string: block.content)) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFit()
                } else {
                    Image(systemName: "photo").foregroundStyle(.secondary).frame(width: 80, height: 80)
                }
            }
        }
    }

    private func badgeContent(_ block: PostcardBlock) -> some View {
        let parts = block.content.split(separator: "|").map(String.init)
        let kind = parts.first.flatMap { StampKind(rawValue: $0) }
        return VStack(spacing: 2) {
            Text(kind?.emoji ?? "🏅").font(.system(size: 30))
            Text(kind?.title ?? "badge")
                .font(.system(size: 8, weight: .heavy))
            if parts.count > 1 {
                Text(appState.memberName(parts[1]))
                    .font(.system(size: 7))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(.white, in: SwiftUI.Circle())
        .overlay(SwiftUI.Circle().strokeBorder(Theme.colorway("mango"), lineWidth: 2.5))
        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
    }

    // MARK: tools

    private func toolBar(_ postcard: Postcard) -> some View {
        VStack(spacing: 8) {
            if let selectedBlockId, let block = postcard.blocks.first(where: { $0.id == selectedBlockId }) {
                selectionControls(block, postcard: postcard)
            }
            HStack(spacing: 18) {
                toolButton("note", "square.and.pencil") { showNoteSheet = true }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    toolLabel("photo", "photo.badge.plus")
                }
                toolButton("sticker", "face.smiling") { showStickerSheet = true }
                toolButton("doodle", "scribble.variable") { doodling = true }
                toolButton("badge", "medal.fill") { showBadgePicker = true }
                    .disabled(vm.hangoutStamps.isEmpty)
                    .opacity(vm.hangoutStamps.isEmpty ? 0.4 : 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func selectionControls(_ block: PostcardBlock, postcard: Postcard) -> some View {
        HStack(spacing: 14) {
            controlButton("rotate.left") { adjust(block, postcard: postcard, dRotation: -12) }
            controlButton("rotate.right") { adjust(block, postcard: postcard, dRotation: 12) }
            controlButton("minus.magnifyingglass") { adjust(block, postcard: postcard, dScale: -0.15) }
            controlButton("plus.magnifyingglass") { adjust(block, postcard: postcard, dScale: 0.15) }
            if block.authorId == appState.authUid {
                controlButton("trash") {
                    vm.deleteBlock(block, from: postcard)
                    selectedBlockId = nil
                }
            }
            Spacer()
            Button("done") { selectedBlockId = nil }
                .font(.caption.bold())
        }
        .padding(.horizontal, 4)
    }

    private func adjust(_ block: PostcardBlock, postcard: Postcard, dRotation: Double = 0, dScale: Double = 0) {
        vm.updatePlacement(block, in: postcard,
                           x: block.x ?? scatterX(block),
                           y: block.y ?? scatterY(block),
                           rotation: (block.rotation ?? 0) + dRotation,
                           scale: min(max((block.scale ?? 1) + dScale, 0.4), 2.2),
                           z: block.z ?? maxZ(postcard))
    }

    private func controlButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 34, height: 34)
                .background(Theme.accentSoft, in: SwiftUI.Circle())
        }
        .buttonStyle(.plain)
    }

    private func toolButton(_ label: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { toolLabel(label, icon) }
            .buttonStyle(.plain)
    }

    private func toolLabel(_ label: String, _ icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 19))
            Text(label).font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(Theme.accent)
    }

    // MARK: footer / locked

    private func footer(_ postcard: Postcard) -> some View {
        VStack(spacing: 2) {
            Text("contributors: \(postcard.contributorIds.map { appState.memberName($0) }.joined(separator: ", "))")
            if let framedBy = postcard.framedBy {
                Text("framed by \(appState.memberName(framedBy))")
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func lockedView(_ postcard: Postcard) -> some View {
        VStack(spacing: 14) {
            Illustration(slot: "locked-capsule", size: 160)
            Text("Time Capsule").font(Theme.title)
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
}

// MARK: - doodle

// Renders an encoded doodle: "colorway|x,y x,y;x,y x,y"
struct DoodleShape: View {
    let encoded: String

    var body: some View {
        let (color, strokes) = Self.decode(encoded)
        GeometryReader { geo in
            SwiftUI.Path { path in
                for stroke in strokes {
                    guard let first = stroke.first else { continue }
                    path.move(to: CGPoint(x: first.x * geo.size.width, y: first.y * geo.size.height))
                    for point in stroke.dropFirst() {
                        path.addLine(to: CGPoint(x: point.x * geo.size.width, y: point.y * geo.size.height))
                    }
                }
            }
            .stroke(Theme.colorway(color), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
        }
    }

    static func decode(_ encoded: String) -> (String, [[CGPoint]]) {
        let parts = encoded.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return ("grape", []) }
        let strokes = parts[1].split(separator: ";").map { stroke in
            stroke.split(separator: " ").compactMap { pair -> CGPoint? in
                let xy = pair.split(separator: ",")
                guard xy.count == 2, let x = Double(xy[0]), let y = Double(xy[1]) else { return nil }
                return CGPoint(x: x, y: y)
            }
        }
        return (parts[0], strokes)
    }
}

// Fullscreen finger-drawing surface.
private struct DoodleView: View {
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var strokes: [[CGPoint]] = []
    @State private var current: [CGPoint] = []
    @State private var color = "grape"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    ZStack {
                        Theme.paper
                        SwiftUI.Path { path in
                            for stroke in strokes + (current.isEmpty ? [] : [current]) {
                                guard let first = stroke.first else { continue }
                                path.move(to: CGPoint(x: first.x * geo.size.width, y: first.y * geo.size.height))
                                for point in stroke.dropFirst() {
                                    path.addLine(to: CGPoint(x: point.x * geo.size.width, y: point.y * geo.size.height))
                                }
                            }
                        }
                        .stroke(Theme.colorway(color), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                current.append(CGPoint(
                                    x: min(max(value.location.x / geo.size.width, 0), 1),
                                    y: min(max(value.location.y / geo.size.height, 0), 1)
                                ))
                            }
                            .onEnded { _ in
                                if current.count > 1 { strokes.append(current) }
                                current = []
                            }
                    )
                }
                HStack(spacing: 12) {
                    ForEach(Array(Theme.colorways.keys.sorted()), id: \.self) { key in
                        SwiftUI.Circle()
                            .fill(Theme.colorway(key))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if key == color {
                                    SwiftUI.Circle().strokeBorder(.white, lineWidth: 2.5)
                                }
                            }
                            .onTapGesture { color = key }
                    }
                    Spacer()
                    Button {
                        _ = strokes.popLast()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(strokes.isEmpty)
                }
                .padding(14)
                .background(.bar)
            }
            .navigationTitle("doodle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("stick it on") {
                        onSave(encode())
                        dismiss()
                    }
                    .disabled(strokes.isEmpty)
                }
            }
        }
    }

    private func encode() -> String {
        // thin the points so the doc stays small
        let encodedStrokes = strokes.map { stroke in
            stride(from: 0, to: stroke.count, by: max(1, stroke.count / 60)).map { i in
                String(format: "%.3f,%.3f", stroke[i].x, stroke[i].y)
            }.joined(separator: " ")
        }.joined(separator: ";")
        return "\(color)|\(encodedStrokes)"
    }
}

// MARK: - small sheets

private struct NoteSheet: View {
    let onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        VStack(spacing: 14) {
            Text("leave a note").font(Theme.heading).padding(.top, 18)
            TextField("what do you remember...", text: $text, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
            Button("stick it on") {
                onAdd(text)
                dismiss()
            }
            .buttonStyle(ChunkyButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}

private struct StickerSheet: View {
    let onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private let stickers = [
        "💖", "😂", "🔥", "🌟", "🫶", "🎉", "🍕", "🌈", "👑", "🦖",
        "😭", "💀", "🥹", "🤌", "🫠", "🎧", "🏆", "🍜", "🌊", "📸",
        "🪩", "🧿", "🚗", "🌙", "✈️", "🍻", "🎂", "⚽️", "🎡", "🌸",
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("sticker book").font(Theme.heading).padding(.top, 18)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                ForEach(stickers, id: \.self) { sticker in
                    Button {
                        onPick(sticker)
                        dismiss()
                    } label: {
                        Text(sticker).font(.system(size: 34))
                    }
                }
            }
            .padding(.horizontal, 16)
            Spacer()
        }
    }
}

private struct CapsuleSheet: View {
    @Binding var date: Date
    let onLock: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            Text("🔒 Time Capsule").font(Theme.heading).padding(.top, 18)
            Text("seal it now, open it later. no peeking in between")
                .font(.caption)
                .foregroundStyle(.secondary)
            DatePicker("unlocks", selection: $date, in: Date().addingTimeInterval(86400)..., displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal, 24)
            Button("lock it in") {
                onLock()
                dismiss()
            }
            .buttonStyle(ChunkyButtonStyle())
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}

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
