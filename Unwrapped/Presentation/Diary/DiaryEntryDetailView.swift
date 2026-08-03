//
//  DiaryEntryDetailView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 27.07.2026.
//

import SwiftUI

struct DiaryEntryDetailView: View {
    let entry: DiaryEntry
    let makeEditViewModel: () -> EntryEditorViewModel?
    let onEntryChanged: () -> Void

    @State private var editingEntryViewModel: EntryEditorViewModel?
    @State private var contentHeight: CGFloat = 200
    @State private var wasNearFullScreen = false
    private let contentAnchorID = "diaryEntryContentTop"
    @Environment(\.dismiss) private var dismiss

    private let navigationBarAllowance: CGFloat = 56

    private var screenHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.height ?? 844
    }

    private var presentationDetents: Set<PresentationDetent> {
        let requiredHeight = contentHeight + navigationBarAllowance
        let isTooTallForCardStyle = requiredHeight > screenHeight * 0.75
        return isTooTallForCardStyle ? [.medium, .large] : [.height(requiredHeight), .medium, .large]
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    content
                        .id(contentAnchorID)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .onGeometryChange(for: CGFloat.self) {
                            $0.size.height
                        } action: { height in
                            contentHeight = height
                        }
                }
                .frame(maxHeight: .infinity)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: { height in
                    let isNearFullScreen = height > screenHeight * 0.65
                    if wasNearFullScreen, !isNearFullScreen {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(contentAnchorID, anchor: .top)
                        }
                    }
                    wasNearFullScreen = isNearFullScreen
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    deleteButton
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        editingEntryViewModel = makeEditViewModel()
                    } label: {
                        Image(systemName: "pencil")
                    }
                }

                ToolbarItem(placement: .principal) {
                    CachedAsyncImage(url: entry.track?.albumImageURL, size: 40) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.secondary.opacity(0.15))
                            Image(systemName: "music.note")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let track = entry.track {
                            SpotifyDeepLink.openTrack(id: track.id)
                        } else {
                            SpotifyDeepLink.openApp()
                        }
                    } label: {
                        Image("SpotifyIconSmall")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .foregroundStyle(.spotifyIcon)
                            .frame(width: 22, height: 22)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .presentationDetents(presentationDetents)
        .sheet(item: $editingEntryViewModel) { viewModel in
            EntryEditorView(
                viewModel: viewModel,
                onSave: onEntryChanged,
                onDelete: {
                    onEntryChanged()
                    dismiss()
                }
            )
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Toolbar

    private var deleteButton: some View {
        Menu {
            Text("Delete this entry?")

            Button(role: .destructive) {
                guard let viewModel = makeEditViewModel() else { return }
                Task {
                    await viewModel.delete()
                    if viewModel.errorMessage == nil {
                        onEntryChanged()
                        dismiss()
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button(role: .cancel) {} label: {
                Label("Cancel", systemImage: "xmark")
            }
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(.red)
        }
        .menuIndicator(.hidden)
    }

    private var entryKindMarker: some View {
        Image(systemName: entry.engagementLevel.systemImage)
            .font(.system(size: 12))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let trackName = entry.track?.name {
                Text(trackName)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            HStack(spacing: 6) {
                Text(formatDayLabel(entry.loggedAt))
                Text("·")
                Text(entry.loggedAt, style: .time)
                Text("·")
                entryKindMarker

                if let progressMs = entry.progressMs {
                    Text("·")
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
                    Text(formatPlaybackTime(ms: progressMs))
                        .fontDesign(.monospaced)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            switch entry.engagementLevel {
            case .quickTap:
                HStack(spacing: 8) {
                    ForEach(entry.tags, id: \.self) { tag in
                        Text("\(tag.emoji) \(tag.label)")
                            .font(.title3)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.secondary.opacity(0.15), in: Capsule())
                    }
                }
            case .detailed:
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                }

                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#if DEBUG
#Preview("Detailed entry") {
    DiaryEntryDetailView(
        entry: .detailedEntry(
            title: "Rainy Sunday",
            trackName: "Holocene",
            note: "Coffee, rain, this song on repeat.",
            hoursAgo: 2
        ),
        makeEditViewModel: { nil },
        onEntryChanged: {}
    )
}

#Preview("Reaction") {
    DiaryEntryDetailView(
        entry: .reaction(trackName: "Midnight City", tag: .energetic, hoursAgo: 5),
        makeEditViewModel: { nil },
        onEntryChanged: {}
    )
}
#endif
