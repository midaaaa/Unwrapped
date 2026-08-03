//
//  SpotifyDeepLink.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 24.07.2026.
//

import UIKit

enum SpotifyDeepLink {
    static func openApp() {
        open(
            appURL: URL(string: "spotify:")!,
            webURL: URL(string: "https://open.spotify.com")!
        )
    }

    static func openTrack(id: String) {
        open(
            appURL: URL(string: "spotify:track:\(id)")!,
            webURL: URL(string: "https://open.spotify.com/track/\(id)")!
        )
    }

    private static func open(appURL: URL, webURL: URL) {
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
}
