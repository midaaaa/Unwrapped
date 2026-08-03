//
//  SpotifyDTOMapperTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

final class SpotifyDTOMapperTests: XCTestCase {
    private func makeTrackDTO(
        id: String = "track1",
        name: String = "Song",
        artists: [TrackDTO.ArtistDTO] = [TrackDTO.ArtistDTO(id: "artist1", name: "Artist")],
        albumImageURLString: String? = "https://example.com/art.jpg"
    ) -> TrackDTO {
        let json = """
        {
            "id": "\(id)",
            "name": "\(name)",
            "duration_ms": 210000,
            "explicit": true,
            "uri": "spotify:track:\(id)",
            "artists": [{"id": "artist1", "name": "Artist"}],
            "album": {
                "name": "Album",
                "images": \(albumImageURLString == nil ? "null" : "[{\"url\": \"\(albumImageURLString!)\"}]")
            }
        }
        """
        return try! JSONDecoder().decode(TrackDTO.self, from: Data(json.utf8))
    }

    func test_mapTrack_populatesFieldsFromDTO() {
        let dto = makeTrackDTO()
        let track = SpotifyDTOMapper.map(dto)

        XCTAssertEqual(track.id, "track1")
        XCTAssertEqual(track.name, "Song")
        XCTAssertEqual(track.artistNames, ["Artist"])
        XCTAssertEqual(track.artistIds, ["artist1"])
        XCTAssertEqual(track.albumName, "Album")
        XCTAssertEqual(track.albumImageURL, URL(string: "https://example.com/art.jpg"))
        XCTAssertEqual(track.durationMs, 210000)
        XCTAssertTrue(track.explicit)
        XCTAssertEqual(track.uri, "spotify:track:track1")
    }

    func test_mapTrack_missingAlbumImages_resultsInNilImageURL() {
        let dto = makeTrackDTO(albumImageURLString: nil)
        let track = SpotifyDTOMapper.map(dto)
        XCTAssertNil(track.albumImageURL)
    }

    func test_mapTopArtist_defaultsMissingOptionalFields() {
        let json = """
        {"id": "artist1", "name": "Artist", "genres": null, "popularity": null, "images": null}
        """
        let dto = try! JSONDecoder().decode(TopArtistDTO.self, from: Data(json.utf8))
        let artist = SpotifyDTOMapper.map(dto)

        XCTAssertEqual(artist.id, "artist1")
        XCTAssertEqual(artist.genres, [])
        XCTAssertEqual(artist.popularity, 0)
        XCTAssertNil(artist.imageURL)
    }

    func test_mapUserProfile_missingDisplayName_fallsBackToUnknown() {
        let json = """
        {"id": "user1", "display_name": null, "country": "RU", "product": "premium", "images": null}
        """
        let dto = try! JSONDecoder().decode(UserProfileDTO.self, from: Data(json.utf8))
        let profile = SpotifyDTOMapper.map(dto)

        XCTAssertEqual(profile.displayName, "Unknown")
        XCTAssertEqual(profile.country, "RU")
    }

    func test_mapCurrentlyPlaying_noItem_returnsNil() {
        let json = """
        {"is_playing": false, "progress_ms": null, "timestamp": 1000, "item": null, "context": null}
        """
        let dto = try! JSONDecoder().decode(CurrentlyPlayingDTO.self, from: Data(json.utf8))
        XCTAssertNil(SpotifyDTOMapper.map(dto))
    }

    func test_mapCurrentlyPlaying_convertsMillisecondTimestampToDate() {
        let dto = CurrentlyPlayingDTO(
            isPlaying: true,
            progressMs: 5000,
            timestamp: 1_700_000_000_000,
            item: makeTrackDTO(),
            context: nil
        )
        let state = SpotifyDTOMapper.map(dto)

        XCTAssertNotNil(state)
        XCTAssertEqual(state?.timestamp, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(state?.progressMs, 5000)
        XCTAssertTrue(state?.isPlaying ?? false)
    }

    func test_mapRecentlyPlayedItem_parsesFractionalISO8601Timestamp() {
        let itemJSON = """
        {"track": \(trackDTOJSON()), "played_at": "2026-08-01T12:34:56.789Z", "context": null}
        """
        let dto = try! JSONDecoder().decode(RecentlyPlayedResponseDTO.ItemDTO.self, from: Data(itemJSON.utf8))
        let item = SpotifyDTOMapper.map(dto)

        XCTAssertNotNil(item)
        let components = Calendar(identifier: .gregorian).dateComponents(
            in: TimeZone(identifier: "UTC")!,
            from: item!.playedAt
        )
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 8)
        XCTAssertEqual(components.day, 1)
    }

    func test_mapRecentlyPlayedItem_parsesPlainISO8601Timestamp() {
        let itemJSON = """
        {"track": \(trackDTOJSON()), "played_at": "2026-08-01T12:34:56Z", "context": null}
        """
        let dto = try! JSONDecoder().decode(RecentlyPlayedResponseDTO.ItemDTO.self, from: Data(itemJSON.utf8))
        XCTAssertNotNil(SpotifyDTOMapper.map(dto))
    }

    func test_mapRecentlyPlayedItem_malformedTimestamp_returnsNil() {
        let itemJSON = """
        {"track": \(trackDTOJSON()), "played_at": "not-a-date", "context": null}
        """
        let dto = try! JSONDecoder().decode(RecentlyPlayedResponseDTO.ItemDTO.self, from: Data(itemJSON.utf8))
        XCTAssertNil(SpotifyDTOMapper.map(dto))
    }

    private func trackDTOJSON() -> String {
        """
        {
            "id": "track1",
            "name": "Song",
            "duration_ms": 210000,
            "explicit": false,
            "uri": "spotify:track:track1",
            "artists": [{"id": "artist1", "name": "Artist"}],
            "album": {"name": "Album", "images": null}
        }
        """
    }
}
