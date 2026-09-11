//
//  StatsViewModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import Foundation

extension TopItemsTimeRange {
    var label: String {
        switch self {
        case .shortTerm: String(localized: "Recent")
        case .mediumTerm: String(localized: "6 Months")
        case .longTerm: String(localized: "All Time")
        }
    }
}

@MainActor
@Observable
final class StatsViewModel {
    var timeRange: TopItemsTimeRange = .shortTerm { didSet { recomputeDerived() } }

    var topTracks: [Track] = []
    var topArtists: [Artist] = [] { didSet { recomputeDerived() } }
    var entries: [DiaryEntry] = [] { didSet { recomputeAll() } }

    var recapPeriod: RecapPeriod = .week { didSet { recomputeRecapState() } }
    private(set) var recapSnapshots: [TasteSnapshot] = [] { didSet { recomputeRecapState() } }

    private(set) var derived = StatsDerived.empty
    private(set) var recapState = RecapState.insufficientData(entriesNeeded: 0, daysRemaining: 0)

    private(set) var derivedRevision = 0

    var topItemsErrorMessage: String?
    var isTopItemsRegionRestricted = false
    var entriesErrorMessage: String?
    var isUnauthenticated = false

    private var loadedTopItemsRange: TopItemsTimeRange?

    private let diaryRepository: DiaryRepositoryProtocol
    private let spotifyRepository: SpotifyRepositoryProtocol
    private let tasteRepository: TasteRepositoryProtocol

    init(
        diaryRepository: DiaryRepositoryProtocol,
        spotifyRepository: SpotifyRepositoryProtocol,
        tasteRepository: TasteRepositoryProtocol
    ) {
        self.diaryRepository = diaryRepository
        self.spotifyRepository = spotifyRepository
        self.tasteRepository = tasteRepository
        recomputeAll()
    }

    // MARK: - Derived data

    private func recomputeAll() {
        recomputeDerived()
        recomputeRecapState()
    }

    private func recomputeDerived() {
        derived = StatsCalculator.derive(
            entries: entries,
            periodStart: periodStart,
            spotifyTopArtist: topArtists.first
        )
        derivedRevision &+= 1
    }

    private func recomputeRecapState() {
        recapState = RecapCalculator.state(entries: entries, snapshots: recapSnapshots, period: recapPeriod)
    }

    // MARK: - Loading

    func loadEntries() async {
        entriesErrorMessage = nil
        do {
            let fetched = try await diaryRepository.fetchAllEntries()
            if fetched == entries {
                recomputeAll()
            } else {
                entries = fetched
            }
        } catch {
            entriesErrorMessage = error.localizedDescription
        }
    }

    func loadRecapSnapshots() async {
        let windows = RecapPeriod.allCases.flatMap { period in
            [RecapCalculator.currentWindow(for: period), RecapCalculator.priorWindow(for: period)]
        }

        var loaded: [TasteSnapshot] = []
        for window in windows {
            guard let snapshot = try? await tasteRepository.fetchLatestSnapshot(from: window.start, to: window.end),
                  !loaded.contains(where: { $0.id == snapshot.id })
            else { continue }
            loaded.append(snapshot)
        }
        recapSnapshots = loaded
    }

    func loadTopItems() async {
        topItemsErrorMessage = nil
        isTopItemsRegionRestricted = false
        isUnauthenticated = false

        do {
            async let tracks = spotifyRepository.fetchTopTracks(timeRange: timeRange, limit: 10)
            async let artists = spotifyRepository.fetchTopArtists(timeRange: timeRange, limit: 10)
            let (fetchedTracks, fetchedArtists) = try await (tracks, artists)
            topTracks = fetchedTracks
            topArtists = fetchedArtists
            loadedTopItemsRange = timeRange
            await saveSnapshot(tracks: fetchedTracks, artists: fetchedArtists)
        } catch AuthError.notAuthenticated {
            isUnauthenticated = true
        } catch APIError.unauthorized {
            isUnauthenticated = true
        } catch APIError.forbidden {
            isTopItemsRegionRestricted = true
            loadedTopItemsRange = timeRange
        } catch {
            if !error.isCancellation {
                topItemsErrorMessage = error.localizedDescription
            }
        }
    }

    func loadTopItemsIfNeeded() async {
        guard loadedTopItemsRange != timeRange else { return }
        await loadTopItems()
    }

    func refreshAll() async {
        async let entriesLoad: Void = loadEntries()
        async let remoteLoad: Void = refreshTopItemsThenSnapshots()
        _ = await (entriesLoad, remoteLoad)
    }

    private func refreshTopItemsThenSnapshots() async {
        await loadTopItems()
        await loadRecapSnapshots()
    }

    private func saveSnapshot(tracks: [Track], artists: [Artist]) async {
        _ = try? await TasteSnapshotRefresher.save(tracks: tracks, artists: artists, into: tasteRepository)
    }

    // MARK: - Drill-down

    func entries(forTrackID trackID: String) -> [DiaryEntry] {
        entries
            .filter { $0.track?.id == trackID }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func entries(forArtistID artistID: String) -> [DiaryEntry] {
        entries
            .filter { entry in
                guard let track = entry.track else { return false }
                return track.artistGroupingKeys.contains { $0.id == artistID }
            }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    // MARK: - Period window

    private var periodStart: Date? {
        let calendar = Calendar.current
        switch timeRange {
        case .shortTerm: return calendar.date(byAdding: .day, value: -28, to: .now)
        case .mediumTerm: return calendar.date(byAdding: .month, value: -6, to: .now)
        case .longTerm: return nil
        }
    }

}
