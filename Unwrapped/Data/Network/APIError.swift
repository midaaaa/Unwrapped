//
//  APIError.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

enum APIError: Error, Sendable {
    case unauthorized
    case forbidden
    case rateLimited(retryAfter: TimeInterval?)
    case noActivePlayback
    case noActiveDevice
    case decodingFailed(underlying: Error)
    case network(underlying: Error)
    case unknown(statusCode: Int, body: String?)
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unauthorized: String(localized: "Unauthorized")
        case .forbidden: String(localized: "Forbidden")
        case .rateLimited(let retryAfter): String(localized: "Rate limited. Try again in \(retryAfter.map(\.description) ?? String(localized: "unknown"))")
        case .noActivePlayback: String(localized: "No active playback")
        case .noActiveDevice: String(localized: "No active Spotify device")
        case .decodingFailed(let underlying): String(localized: "Failed to decode: \(underlying.localizedDescription)")
        case .network(let underlying): String(localized: "Network error: \(underlying.localizedDescription)")
        case .unknown(let statusCode, let body): String(localized: "Unknown error: \(statusCode), \(body?.prefix(100) ?? "")")
        }
    }
}
