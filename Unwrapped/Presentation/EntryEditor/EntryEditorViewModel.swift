//
//  EntryEditorViewModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 25.07.2026.
//

import Foundation

@MainActor
@Observable
final class EntryEditorViewModel: Identifiable {
    let id = UUID()
    var selectedTags: Set<MoodTag> = []
    static let titleCharacterLimit = 50
    var title = ""
    var body = ""

    var titleOverflowTrigger = 0

    var titleRemaining: Int { Self.titleCharacterLimit - title.count }

    var progressMs: Int
    var errorMessage: String?
    var isSaving = false
    let track: Track
    private let diaryRepository: DiaryRepositoryProtocol
    private let existingEntry: DiaryEntry?

    private let initialTags: Set<MoodTag>
    private let initialTitle: String
    private let initialBody: String
    private let initialProgressMs: Int

    let originalKind: EngagementLevel
    private(set) var currentKind: EngagementLevel

    var pickableDurationMs: Int { (track.durationMs / 1_000) * 1_000 }

    var showsToggle: Bool { originalKind == .quickTap }
    var canDelete: Bool { existingEntry != nil }

    var selectedReactionTag: MoodTag? {
        selectedTags.count == 1 ? selectedTags.first : nil
    }

    // MARK: - Kind & unsaved-changes tracking

    var isEmpty: Bool {
        switch currentKind {
        case .quickTap:
            return selectedReactionTag == nil
        case .detailed:
            return title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var hasUnsavedChanges: Bool {
        guard !isEmpty else { return false }
        return currentKind != originalKind
            || selectedTags != initialTags
            || title != initialTitle
            || body != initialBody
            || progressMs != initialProgressMs
    }

    // MARK: - Initialization

    enum Mode {
        case create(initialProgressMs: Int, kind: EngagementLevel = .detailed, playedAt: Date? = nil)
        case edit(DiaryEntry)
    }

    private let playedAtOverride: Date?

    init(track: Track, mode: Mode, diaryRepository: DiaryRepositoryProtocol) {
        self.track = track
        self.diaryRepository = diaryRepository
        switch mode {
        case .create(let initialProgressMs, let kind, let playedAt):
            self.progressMs = initialProgressMs
            self.existingEntry = nil
            self.originalKind = kind
            self.currentKind = kind
            self.initialTags = []
            self.initialTitle = ""
            self.initialBody = ""
            self.initialProgressMs = initialProgressMs
            self.playedAtOverride = playedAt
        case .edit(let entry):
            let pickableDurationMs = (track.durationMs / 1_000) * 1_000
            let snappedMs = roundedToNearestSecond(ms: entry.progressMs ?? 0, clampedToDurationMs: pickableDurationMs)
            self.progressMs = snappedMs
            self.title = entry.title ?? ""
            self.body = entry.note ?? ""
            self.selectedTags = Set(entry.tags)
            self.existingEntry = entry
            self.originalKind = entry.engagementLevel
            self.currentKind = entry.engagementLevel
            self.initialTags = Set(entry.tags)
            self.initialTitle = entry.title ?? ""
            self.initialBody = entry.note ?? ""
            self.initialProgressMs = snappedMs
            self.playedAtOverride = nil
        }
    }

    // MARK: - Actions

    func selectReactionTag(_ tag: MoodTag) {
        selectedTags = [tag]
    }

    func toggleKind() {
        guard showsToggle else { return }
        currentKind = currentKind == .quickTap ? .detailed : .quickTap
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }

        let entry: DiaryEntry
        switch currentKind {
        case .quickTap:
            entry = DiaryEntry(
                id: existingEntry?.id ?? UUID(),
                loggedAt: existingEntry?.loggedAt ?? Date.now,
                playedAt: existingEntry?.playedAt ?? playedAtOverride ?? Date.now,
                engagementLevel: .quickTap,
                tags: selectedReactionTag.map { [$0] } ?? [],
                title: nil,
                note: nil,
                progressMs: progressMs,
                track: track
            )
        case .detailed:
            entry = DiaryEntry(
                id: existingEntry?.id ?? UUID(),
                loggedAt: existingEntry?.loggedAt ?? Date.now,
                playedAt: existingEntry?.playedAt ?? playedAtOverride ?? Date.now,
                engagementLevel: .detailed,
                tags: [],
                title: title.isEmpty ? nil : title,
                note: body.isEmpty ? nil : body,
                progressMs: progressMs,
                track: track
            )
        }

        do {
            try await diaryRepository.save(entry)
        } catch {
            if !error.isCancellation {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func delete() async {
        guard let existingEntry else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            try await diaryRepository.deleteEntry(id: existingEntry.id)
        } catch {
            if !error.isCancellation {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
