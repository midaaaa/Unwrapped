//
//  KeychainTokenStoreProtocol.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

struct AuthTokens: Sendable, Equatable {
    let accessToken: String
    let refreshToken: String?
}

protocol KeychainTokenStoreProtocol: Sendable {
    func save(_ tokens: AuthTokens) throws
    func load() throws -> AuthTokens?
    func clear() throws
}
