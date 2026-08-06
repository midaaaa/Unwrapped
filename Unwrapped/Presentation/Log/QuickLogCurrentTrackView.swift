//
//  QuickLogCurrentTrackView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import SwiftUI

struct QuickLogCurrentTrackView: View {
    let spotifyRepository: SpotifyRepositoryProtocol
    let diaryRepository: DiaryRepositoryProtocol
    var onEntryLogged: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var entryEditorViewModel: EntryEditorViewModel?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let entryEditorViewModel {
                EntryEditorView(
                    viewModel: entryEditorViewModel,
                    onSave: {
                        onEntryLogged()
                        dismiss()
                    },
                    onDelete: { dismiss() }
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await fetchCurrentTrack()
        }
        .alert(
            "Couldn't log current track",
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button("OK") { dismiss() }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func fetchCurrentTrack() async {
        do {
            switch try await spotifyRepository.fetchCurrentlyPlaying() {
            case .active(let state):
                let pickableDurationMs = (state.track.durationMs / 1_000) * 1_000
                let snappedMs = roundedToNearestSecond(ms: state.progressMs, clampedToDurationMs: pickableDurationMs)
                entryEditorViewModel = EntryEditorViewModel(
                    track: state.track,
                    mode: .create(initialProgressMs: snappedMs, kind: .quickTap),
                    diaryRepository: diaryRepository
                )
            case .noActivePlayback:
                errorMessage = String(localized: "Nothing is playing right now.")
            }
        } catch AuthError.notAuthenticated {
            errorMessage = String(localized: "Sign in with Spotify to log a track.")
        } catch APIError.noActiveDevice {
            errorMessage = String(localized: "No active Spotify device")
        } catch {
            if !error.isCancellation {
                errorMessage = error.localizedDescription
            }
        }
    }
}
