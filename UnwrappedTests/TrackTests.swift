//
//  TrackTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

final class TrackTests: XCTestCase {
    private func track(
        artistNames: [String],
        artistIds: [String] = [],
        artistImageURLs: [URL?] = []
    ) -> Track {
        Track(
            id: "t1",
            name: "Song",
            artistNames: artistNames,
            artistIds: artistIds,
            albumName: "Album",
            durationMs: 200_000,
            explicit: false,
            uri: "spotify:track:t1",
            artistImageURLs: artistImageURLs
        )
    }

    // MARK: - primaryArtistName / artistDisplaySummary

    func test_primaryArtistName_returnsFirstArtist() {
        XCTAssertEqual(track(artistNames: ["First", "Second"]).primaryArtistName, "First")
    }

    func test_primaryArtistName_noArtists_fallsBackToUnknown() {
        XCTAssertEqual(track(artistNames: []).primaryArtistName, String(localized: "Unknown Artist"))
    }

    func test_artistDisplaySummary_singleArtist_showsNameOnly() {
        XCTAssertEqual(track(artistNames: ["Solo"]).artistDisplaySummary, "Solo")
    }

    func test_artistDisplaySummary_multipleArtists_showsCountSuffix() {
        XCTAssertEqual(track(artistNames: ["First", "Second", "Third"]).artistDisplaySummary, "First +2")
    }

    // MARK: - artistGroupingKeys

    func test_artistGroupingKeys_withIds_zipsIdsAndNames() {
        let keys = track(artistNames: ["First", "Second"], artistIds: ["a1", "a2"]).artistGroupingKeys
        XCTAssertEqual(keys.map(\.id), ["a1", "a2"])
        XCTAssertEqual(keys.map(\.name), ["First", "Second"])
    }

    func test_artistGroupingKeys_noIdsButHasNames_fallsBackToNameAsId() {
        let keys = track(artistNames: ["OnlyName"], artistIds: []).artistGroupingKeys
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys.first?.id, "OnlyName")
        XCTAssertEqual(keys.first?.name, "OnlyName")
    }

    func test_artistGroupingKeys_noArtistsAtAll_returnsEmpty() {
        XCTAssertTrue(track(artistNames: [], artistIds: []).artistGroupingKeys.isEmpty)
    }

    // MARK: - imageURL(forArtistId:)

    func test_imageURLForArtistId_returnsMatchingURLByIndex() {
        let url1 = URL(string: "https://example.com/a1.jpg")
        let url2 = URL(string: "https://example.com/a2.jpg")
        let t = track(artistNames: ["First", "Second"], artistIds: ["a1", "a2"], artistImageURLs: [url1, url2])

        XCTAssertEqual(t.imageURL(forArtistId: "a2"), url2)
    }

    func test_imageURLForArtistId_unknownId_returnsNil() {
        let t = track(artistNames: ["First"], artistIds: ["a1"], artistImageURLs: [URL(string: "https://example.com/a1.jpg")])
        XCTAssertNil(t.imageURL(forArtistId: "unknown"))
    }

    func test_imageURLForArtistId_indexOutOfBoundsInImageArray_returnsNil() {
        let t = track(artistNames: ["First"], artistIds: ["a1"], artistImageURLs: [])
        XCTAssertNil(t.imageURL(forArtistId: "a1"))
    }
}
