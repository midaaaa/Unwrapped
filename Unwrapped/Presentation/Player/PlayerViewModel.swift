//
//  PlayerViewModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

@MainActor
@Observable
final class PlayerViewModel {
    private(set) var currentlyPlaying: PlaybackResponse<CurrentlyPlayingState>?

    private(set) var displayState: PlaybackResponse<CurrentlyPlayingState>?

    var errorMessage: String?

    private let repository: SpotifyRepositoryProtocol
    private let diaryRepository: DiaryRepositoryProtocol
    var progressAnchor: PlaybackProgressAnchor?
    var savingMoodTag: MoodTag?
    @ObservationIgnored
    nonisolated(unsafe) private var pollingTask: Task<Void, Never>?
    @ObservationIgnored
    nonisolated(unsafe) private var endOfTrackTask: Task<Void, Never>?
    @ObservationIgnored
    nonisolated(unsafe) private var collapseTask: Task<Void, Never>?

    private static let collapseGraceSeconds: Double = 8

    @ObservationIgnored
    private var pendingPlaybackCommand: (isPlaying: Bool, expiresAt: Date)?
    private static let pendingCommandGraceSeconds: Double = 4

    init(
        repository: SpotifyRepositoryProtocol,
        diaryRepository: DiaryRepositoryProtocol,
        initialState: PlaybackResponse<CurrentlyPlayingState>? = nil
    ) {
        self.repository = repository
        self.diaryRepository = diaryRepository
        if let initialState {
            currentlyPlaying = initialState
            displayState = initialState
            updateProgressAnchor(for: initialState)
        }
    }

    deinit {
        pollingTask?.cancel()
        endOfTrackTask?.cancel()
        collapseTask?.cancel()
    }

    // MARK: - Currently playing

    var currentTrack: Track? {
        if case .active(let state) = displayState { return state.track }
        return nil
    }

    private func setCurrentlyPlaying(_ newValue: PlaybackResponse<CurrentlyPlayingState>?) {
        currentlyPlaying = newValue

        if case .active = newValue {
            collapseTask?.cancel()
            collapseTask = nil
            displayState = newValue
            updateProgressAnchor(for: newValue)
            return
        }

        guard case .active = displayState else {
            displayState = newValue
            updateProgressAnchor(for: newValue)
            return
        }

        collapseTask?.cancel()
        collapseTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(Self.collapseGraceSeconds))
            } catch {
                return
            }
            guard let self, !Task.isCancelled else { return }
            self.displayState = self.currentlyPlaying
            self.updateProgressAnchor(for: self.currentlyPlaying)
        }
    }

    func load() async {
        errorMessage = nil

        do {
            let startTime = ContinuousClock.now
            let playingState = try await repository.fetchCurrentlyPlaying()
            let networkDuration = startTime.duration(to: .now)

            let adjustedState = adjustProgressForNetworkDelay(playingState, delay: networkDuration)
            setCurrentlyPlaying(adjustedState)
        } catch {
            if !error.isTransientNetworkGlitch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Track entries (timeline lane)

    private(set) var trackEntries: [DiaryEntry] = []

    func refreshTrackEntries(forTrackID trackID: String?) async {
        guard let trackID else {
            trackEntries = []
            return
        }
        let fetched = (try? await diaryRepository.fetchEntries(forTrackID: trackID)) ?? []
        trackEntries = TimelineActiveEntryResolver.sorted(fetched)
    }

    // MARK: - Polling

    func startPolling(interval: Duration = .seconds(5)) {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while true {
                guard let self, !Task.isCancelled else { return }
                do { try await Task.sleep(for: interval) } catch { break }
                await refreshCurrentlyPlaying()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil

        endOfTrackTask?.cancel()
        endOfTrackTask = nil
        progressAnchor = nil
    }

    func refreshNow() async {
        await refreshCurrentlyPlaying()
    }

    // MARK: - Playback control

    func togglePlayback() {
        guard case .active(let state) = displayState else { return }
        let wasPlaying = state.isPlaying
        let toggled = CurrentlyPlayingState(
            track: state.track,
            isPlaying: !wasPlaying,
            progressMs: state.progressMs,
            timestamp: state.timestamp,
            context: state.context
        )
        pendingPlaybackCommand = (isPlaying: !wasPlaying, expiresAt: Date().addingTimeInterval(Self.pendingCommandGraceSeconds))
        setCurrentlyPlaying(.active(toggled))

        Task {
            do {
                if wasPlaying {
                    try await repository.pause()
                } else {
                    try await repository.play()
                }
            } catch APIError.noActiveDevice {
                pendingPlaybackCommand = nil
                setCurrentlyPlaying(.active(state))
            } catch {
                if !error.isTransientNetworkGlitch {
                    errorMessage = error.localizedDescription
                }
                pendingPlaybackCommand = nil
                setCurrentlyPlaying(.active(state))
            }
        }
    }

    // MARK: - Logging

    func logQuickReaction(_ tag: MoodTag) async {
        guard let track = currentTrack else { return }

        savingMoodTag = tag
        defer { savingMoodTag = nil }

        let rawProgressMs = progressAnchor?.progressMs(at: Date())
        let snappedProgressMs = rawProgressMs.map { roundedToNearestSecond(ms: $0) }

        let entry = DiaryEntry(
            id: UUID(),
            loggedAt: Date(),
            playedAt: Date(),
            engagementLevel: .quickTap,
            tags: [tag],
            title: nil,
            note: nil,
            progressMs: snappedProgressMs,
            track: track
        )

        do {
            let saved = try await diaryRepository.save(entry)
            trackEntries = TimelineActiveEntryResolver.sorted(trackEntries + [saved])
        } catch {
            if !error.isTransientNetworkGlitch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func makeEntryEditorViewModel(existingEntry: DiaryEntry? = nil) -> EntryEditorViewModel? {
        if let existingEntry {
            guard let track = existingEntry.track else { return nil }
            return EntryEditorViewModel(
                track: track,
                mode: .edit(existingEntry),
                diaryRepository: diaryRepository
            )
        }

        guard let track = currentTrack else { return nil }
        let rawMs = progressAnchor?.progressMs(at: Date()) ?? 0
        let pickableDurationMs = (track.durationMs / 1_000) * 1_000
        let snappedMs = roundedToNearestSecond(ms: rawMs, clampedToDurationMs: pickableDurationMs)
        return EntryEditorViewModel(
            track: track,
            mode: .create(initialProgressMs: snappedMs),
            diaryRepository: diaryRepository
        )
    }

    // MARK: - Private helpers

    private func refreshCurrentlyPlaying() async {
        do {
            let startTime = ContinuousClock.now
            let playingState = try await repository.fetchCurrentlyPlaying()
            let networkDuration = startTime.duration(to: .now)

            let fetchedState = adjustProgressForNetworkDelay(playingState, delay: networkDuration)

            if shouldUpdateState(newResponse: fetchedState) {
                setCurrentlyPlaying(fetchedState)
            }
        } catch {
            if !error.isTransientNetworkGlitch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func shouldUpdateState(newResponse: PlaybackResponse<CurrentlyPlayingState>) -> Bool {
        guard let current = currentlyPlaying else { return true }

        switch (current, newResponse) {
        case (.active(let currState), .active(let newState)):
            if currState.track.id != newState.track.id { return true }

            if let pending = pendingPlaybackCommand {
                if Date() < pending.expiresAt && newState.isPlaying != pending.isPlaying {
                    return false
                }
                pendingPlaybackCommand = nil
            }
            if currState.isPlaying != newState.isPlaying { return true }

            let expectedProgressMs = progressAnchor?.progressMs(at: Date()) ?? currState.progressMs
            let diff = abs(expectedProgressMs - newState.progressMs)
            if diff > 2000 { return true }

            return false

        default:
            return true
        }
    }

    private func adjustProgressForNetworkDelay(_ response: PlaybackResponse<CurrentlyPlayingState>, delay: Duration) -> PlaybackResponse<CurrentlyPlayingState> {
        guard case .active(var state) = response, state.isPlaying else { return response }
        let delayMs = Int(delay.components.seconds * 1000 + Int64(delay.components.attoseconds / 1_000_000_000_000_000))
        state.progressMs = min(state.track.durationMs, state.progressMs + delayMs)
        return .active(state)
    }

    private func updateProgressAnchor(for response: PlaybackResponse<CurrentlyPlayingState>?) {
        guard case .active(let state) = response else {
            progressAnchor = nil
            endOfTrackTask?.cancel()
            return
        }
        let anchor = PlaybackProgressAnchor(
            baseProgressMs: state.progressMs,
            referenceDate: Date(),
            isPlaying: state.isPlaying,
            durationMs: state.track.durationMs
        )
        progressAnchor = anchor
        scheduleEndOfTrack(for: anchor)
    }

    private static let endOfTrackBufferMs = 300

    private func scheduleEndOfTrack(for anchor: PlaybackProgressAnchor) {
        endOfTrackTask?.cancel()
        endOfTrackTask = nil

        guard anchor.isPlaying else { return }
        let remainingMs = anchor.durationMs - anchor.baseProgressMs
        guard remainingMs > 0 else { return }

        endOfTrackTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: .milliseconds(remainingMs + Self.endOfTrackBufferMs))
            } catch {
                return
            }
            await self.refreshCurrentlyPlaying()
        }
    }
}
