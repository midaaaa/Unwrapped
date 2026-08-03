//
//  SpotifyConfig.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

enum SpotifyConfig {
    nonisolated static let clientID = "2646f57c26374ff8b7f357df4b6b807f"
    nonisolated static let redirectURI = "unwrapped://callback"
    nonisolated static let authorizationEndpoint = URL(string: "https://accounts.spotify.com/authorize")!
    nonisolated static let tokenEndpoint = URL(string: "https://accounts.spotify.com/api/token")!
    nonisolated static let apiBase = URL(string: "https://api.spotify.com/v1")!

    static let scopes = [
        "user-read-private",
        "user-read-recently-played",
        "user-top-read",
        "user-read-currently-playing",
        "user-read-playback-state",
        "user-modify-playback-state",
    ].joined(separator: " ")
}
