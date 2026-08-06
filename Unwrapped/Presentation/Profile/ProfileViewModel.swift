//
//  ProfileViewModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    var profile: UserProfile?
    var errorMessage: String?
    var storageErrorMessage: String?

    private let repository: SpotifyRepositoryProtocol
    private let diaryRepository: DiaryRepositoryProtocol
    private let tasteRepository: TasteRepositoryProtocol

    init(
        repository: SpotifyRepositoryProtocol,
        diaryRepository: DiaryRepositoryProtocol,
        tasteRepository: TasteRepositoryProtocol
    ) {
        self.repository = repository
        self.diaryRepository = diaryRepository
        self.tasteRepository = tasteRepository
    }

    func load() async {
        errorMessage = nil

        do {
            profile = try await repository.fetchProfile()
        } catch {
            if !error.isCancellation {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearCache() async {
        storageErrorMessage = nil
        do {
            try await tasteRepository.clearOrphanedCache()
            ImageMemoryCache.shared.clear()
        } catch {
            if !error.isCancellation {
                storageErrorMessage = error.localizedDescription
            }
        }
    }

    func deleteAllData() async {
        storageErrorMessage = nil
        do {
            try await diaryRepository.deleteAllEntries()
            try await tasteRepository.deleteAllSnapshots()
            try await tasteRepository.clearOrphanedCache()
            ImageMemoryCache.shared.clear()
        } catch {
            if !error.isCancellation {
                storageErrorMessage = error.localizedDescription
            }
        }
    }

    #if DEBUG
    private static let sampleTitles = [
        "Late night", "Morning drive", "Rainy day", "Gym session", "Study session",
        "Long walk", "Road trip", "Quiet evening", "First listen", "On repeat"
    ]

    private static let sampleNotes = [
        "Can't stop playing this one.", "Perfect for this mood.", "Windows down, volume up.",
        "This hit different today.", "Adding to the favorites playlist.", "Been stuck in my head all day.",
        "Exactly what I needed right now.", nil, nil
    ]

    func seedRandomEntries(count: Int = 40) async {
        storageErrorMessage = nil
        do {
            let recentlyPlayed = try await repository.fetchRecentlyPlayed(limit: 50, before: nil)
            guard !recentlyPlayed.isEmpty else { return }

            let calendar = Calendar.current
            for _ in 0..<count {
                let track = recentlyPlayed.randomElement()!.track
                let isDetailed = Bool.random()

                let daysAgo = Int.random(in: 0...90)
                let secondsIntoDay = Int.random(in: 0..<86_400)
                let day = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
                let loggedAt = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: day)
                    .map { $0.addingTimeInterval(TimeInterval(secondsIntoDay)) } ?? day

                let entry = DiaryEntry(
                    id: UUID(),
                    loggedAt: loggedAt,
                    playedAt: loggedAt,
                    engagementLevel: isDetailed ? .detailed : .quickTap,
                    tags: isDetailed ? [] : [MoodTag.allCases.randomElement()!],
                    title: isDetailed ? Self.sampleTitles.randomElement() : nil,
                    note: isDetailed ? (Self.sampleNotes.randomElement() ?? nil) : nil,
                    progressMs: track.durationMs > 0 ? Int.random(in: 0..<track.durationMs) : 0,
                    track: track
                )
                try await diaryRepository.save(entry)
            }
        } catch {
            storageErrorMessage = error.localizedDescription
        }
    }
    #endif
}
