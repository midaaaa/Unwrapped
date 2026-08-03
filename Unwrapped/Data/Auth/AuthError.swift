//
//  AuthError.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

enum AuthError: Error {
    case noPresentationAnchor
    case noAuthorizationCode
    case notAuthenticated
    case tokenExchangeFailed(statusCode: Int, body: String?)
    case userCancelled
}

extension AuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noPresentationAnchor: String(localized: "No presentation anchor available")
        case .noAuthorizationCode: String(localized: "No authorization code received")
        case .notAuthenticated: String(localized: "Not authenticated")
        case .tokenExchangeFailed(statusCode: let statusCode, body: let body):
            String(localized: "Failed to exchange token: \(statusCode) \(body?.prefix(100) ?? "")")
        case .userCancelled: String(localized: "User cancelled")
        }
    }
}
