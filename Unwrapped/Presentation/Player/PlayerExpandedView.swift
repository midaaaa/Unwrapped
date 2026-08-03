//
//  PlayerExpandedView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import SwiftUI

enum PlayerDetailMode {
    case live
    case reviewing(DiaryEntry)
}

struct PlayerExpandedView: View {
    @Bindable var viewModel: PlayerViewModel
    let namespace: Namespace.ID
    var mode: PlayerDetailMode = .live
    var onEntryLogged: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @AppStorage(AppSettingsKeys.activeCardWindowSeconds) private var activeCardWindowSeconds = 4

    @State private var blurredBackgroundImage: UIImage?
    @State private var albumCenterY: CGFloat?
    @State private var isBackgroundVisible = false
    @State private var entryEditorViewModel: EntryEditorViewModel?
    @State private var reviewingEntry: DiaryEntry?

    private var isLiveTrack: Bool {
        guard case .active(let state) = viewModel.displayState else { return false }
        switch mode {
        case .live: return true
        case .reviewing(let entry): return state.track.id == entry.track?.id
        }
    }

    private var resolvedTrack: Track? {
        if isLiveTrack, case .active(let state) = viewModel.displayState { return state.track }
        switch mode {
        case .live: return nil
        case .reviewing(let entry): return entry.track
        }
    }

    private var zoomSourceID: AnyHashable {
        switch mode {
        case .live: PlayerCompactView.transitionSourceID
        case .reviewing(let entry): entry.id
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        if let track = resolvedTrack {
                            content(for: track, screenWidth: proxy.size.width, screenHeight: proxy.size.height)
                        } else {
                            ContentUnavailableView(
                                "Nothing playing",
                                systemImage: "music.note",
                                description: Text("Start Spotify on any device with the same account.")
                            )
                        }
                    }
                    .padding(.horizontal, Self.contentPadding)
                    .padding(.top, Self.contentPadding)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaInset(edge: .bottom) { unwrapButton }
            .toolbar {
                Button {
                    if let track = resolvedTrack {
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
        .navigationTransition(.zoom(sourceID: zoomSourceID, in: namespace))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: "player")
        .background {
            ZStack {
                Color(.systemBackground)
                GeometryReader { proxy in
                    coverBackground(width: proxy.size.width)
                }
                (colorScheme == .dark ? Color.black : Color.white)
                    .opacity(0.35)
            }
            .ignoresSafeArea()
        }
        .task(id: resolvedTrack?.id) {
            await viewModel.refreshTrackEntries(forTrackID: resolvedTrack?.id)
        }
        .errorAlert("Playback error", message: $viewModel.errorMessage)
        .sheet(item: $entryEditorViewModel) { entryEditorViewModel in
            EntryEditorView(
                viewModel: entryEditorViewModel,
                onSave: handleEntryChange,
                onDelete: handleEntryChange
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $reviewingEntry) { entry in
            DiaryEntryDetailView(
                entry: entry,
                makeEditViewModel: { viewModel.makeEntryEditorViewModel(existingEntry: entry) },
                onEntryChanged: handleEntryChange
            )
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleEntryChange() {
        onEntryLogged()
        Task {
            await viewModel.refreshTrackEntries(forTrackID: resolvedTrack?.id)
            if let reviewingEntry {
                self.reviewingEntry = viewModel.trackEntries.first { $0.id == reviewingEntry.id }
            }
        }
    }

    @ViewBuilder
    private func content(for track: Track, screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        let albumArtSize = Self.albumArtSize(forScreenHeight: screenHeight)
        GeometryReader { proxy in
            albumArt(url: track.albumImageURL, maxWidth: proxy.size.width, artSize: albumArtSize)
                .frame(maxWidth: .infinity)
        }
        .frame(height: albumArtSize)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .named("player")).midY
        } action: { albumCenterY = $0 }
        .padding(.bottom, Self.sectionSpacing)

        trackInfo(track)
            .padding(.bottom, Self.trackInfoBottomSpacing)

        progressSection(durationMs: track.durationMs)

        if isLiveTrack, case .active(let state) = viewModel.displayState {
            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: Self.playButtonSize))
            }
            .buttonStyle(.plain)
            .padding(.bottom, Self.playButtonBottomSpacing)

            moodChipRow
                .padding(.bottom, 8)

            entryTimelineLane(screenWidth: screenWidth)
        } else {
            entryTimelineLane(screenWidth: screenWidth)
                .padding(.top, Self.sectionSpacing)
        }
    }

    @ViewBuilder
    private var unwrapButton: some View {
        if isLiveTrack, case .active = viewModel.displayState {
            Button {
                entryEditorViewModel = viewModel.makeEntryEditorViewModel()
            } label: {
                Text("UNWRAP")
                    .padding(.vertical, Self.unwrapButtonVerticalPadding)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .padding(.horizontal, Self.unwrapButtonHorizontalPadding)
        }
    }

    private func entryTimelineLane(screenWidth: CGFloat) -> some View {
        EntryTimelineLaneView(
            entries: viewModel.trackEntries,
            activeCardWindowSeconds: activeCardWindowSeconds,
            isLive: isLiveTrack,
            progressAnchor: viewModel.progressAnchor,
            outerHorizontalPadding: Self.contentPadding,
            screenWidth: screenWidth,
            onTapEntry: { reviewingEntry = $0 }
        )
    }

    private func artistText(for track: Track) -> Text {
        guard track.explicit else { return Text(track.artistNames.joined(separator: ", ")) }
        return Text.withExplicitBadge(
            track.artistNames.joined(separator: ", "),
            colorScheme: colorScheme,
            displayScale: displayScale
        )
    }

    private func trackInfo(_ track: Track) -> some View {
        VStack(spacing: 6) {
            Text(track.name)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .stableFullWidth()
            artistText(for: track)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .stableFullWidth()
        }
    }

    @ViewBuilder
    private func progressSection(durationMs: Int) -> some View {
        if isLiveTrack, let anchor = viewModel.progressAnchor {
            let durationText = formatPlaybackTime(ms: anchor.durationMs)
            TimelineView(.animation(paused: !anchor.isPlaying)) { context in
                let progressMs = anchor.progressMs(at: context.date)
                let elapsedSeconds = progressMs / 1_000
                VStack(alignment: .leading, spacing: 2) {
                    progressBar(fraction: fraction(progressMs: progressMs, durationMs: anchor.durationMs))
                    HStack {
                        Text(formatPlaybackTime(ms: progressMs))
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: elapsedSeconds)
                        Spacer()
                        Text(durationText)
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
                .animation(.easeOut(duration: 0.3), value: anchor)
            }
        } else if case .reviewing(let entry) = mode {
            let progressMs = entry.progressMs ?? 0
            VStack(alignment: .leading, spacing: 4) {
                progressBar(fraction: fraction(progressMs: progressMs, durationMs: durationMs))
                HStack {
                    Text(formatPlaybackTime(ms: progressMs))
                    Spacer()
                    Text(formatPlaybackTime(ms: durationMs))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        }
    }

    private var moodChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MoodTag.allCases, id: \.self) { tag in
                    moodChip(tag)
                }
            }
        }
        .scrollClipDisabled()
        .stableFullWidth()
    }

    private func moodChip(_ tag: MoodTag) -> some View {
        let isSaving = viewModel.savingMoodTag == tag

        return Button {
            Task {
                await viewModel.logQuickReaction(tag)
                onEntryLogged()
            }
        } label: {
            HStack(spacing: 4) {
                Text(tag.emoji)
                    .opacity(isSaving ? 0 : 1)
                    .overlay {
                        if isSaving {
                            ProgressView()
                                .controlSize(.mini)
                        }
                    }
                Text(tag.label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.secondary.opacity(0.15), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.savingMoodTag != nil)
    }

    private func progressBar(fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.secondary.opacity(0.25))
                Capsule()
                    .fill(.primary)
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 4)
    }

    private static let contentPadding: CGFloat = 16
    private static let sectionSpacing: CGFloat = 24
    private static let trackInfoBottomSpacing: CGFloat = 12
    private static let playButtonBottomSpacing: CGFloat = 8
    private static let playButtonSize: CGFloat = 60
    private static let unwrapButtonVerticalPadding: CGFloat = 10
    private static let unwrapButtonHorizontalPadding: CGFloat = contentPadding * 2

    private static let albumArtSizeFraction: CGFloat = 0.3
    private static let albumArtSizeRange: ClosedRange<CGFloat> = 220...300

    private static func albumArtSize(forScreenHeight height: CGFloat) -> CGFloat {
        min(albumArtSizeRange.upperBound, max(albumArtSizeRange.lowerBound, height * albumArtSizeFraction))
    }

    private func albumArtCornerRadius(forArtSize artSize: CGFloat) -> CGFloat {
        artSize * 0.1
    }

    private func albumArt(url: URL?, maxWidth: CGFloat, artSize: CGFloat) -> some View {
        CachedAsyncImage(
            url: url,
            size: artSize,
            maxWidth: maxWidth,
            placeholder: { albumPlaceholder },
            onLoad: handleArtworkLoaded
        )
        .clipShape(RoundedRectangle(cornerRadius: albumArtCornerRadius(forArtSize: artSize), style: .continuous))
    }

    private var albumPlaceholder: some View {
        ZStack {
            Color.secondary.opacity(0.2)
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
    }

    private func handleArtworkLoaded(_ image: UIImage?) {
        isBackgroundVisible = false
        blurredBackgroundImage = nil
        guard let image else { return }

        Task.detached(priority: .userInitiated) {
            let blurredImage = AlbumBackgroundRenderer.blurredExpanded(from: image)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.6)) {
                    blurredBackgroundImage = blurredImage
                    isBackgroundVisible = true
                }
            }
        }
    }

    @ViewBuilder
    private func coverBackground(width: CGFloat) -> some View {
        if let blurredBackgroundImage {
            let side = width * 1.6
            Image(uiImage: blurredBackgroundImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: side, height: side)
                .mask(bottomFadeMask)
                .position(x: width / 2, y: albumCenterY ?? 0)
                .opacity(isBackgroundVisible ? 0.9 : 0)
        }
    }

    private var bottomFadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: 0.6),
                .init(color: .clear, location: 0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func fraction(progressMs: Int, durationMs: Int) -> Double {
        guard durationMs > 0 else { return 0 }
        return min(1, Double(progressMs) / Double(durationMs))
    }
}

#if DEBUG
private struct PlayerDetailPreviewContainer: View {
    @Namespace private var namespace

    var body: some View {
        PlayerExpandedView(viewModel: .preview(), namespace: namespace)
    }
}

private struct PlayerDetailReviewingPreviewContainer: View {
    @Namespace private var namespace

    var body: some View {
        PlayerExpandedView(
            viewModel: .preview(currentlyPlaying: .noActivePlayback),
            namespace: namespace,
            mode: .reviewing(DiaryEntry.previewEntriesForCurrentTrack[0])
        )
    }
}

#Preview("Live") {
    PlayerDetailPreviewContainer()
}

#Preview("Reviewing (not playing)") {
    PlayerDetailReviewingPreviewContainer()
}
#endif
