//
//  KeychainTokenStore.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation
import Security

final class KeychainTokenStore: KeychainTokenStoreProtocol, Sendable {
    private let service = "mida.Unwrapped.spotify"
    private let accessAccount = "access_token"
    private let refreshAccount = "refresh_token"

    private func save(_ value: String, account: String) throws {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func read(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.readFailed(status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataCorrupted
        }

        return string
    }

    private func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    func save(_ tokens: AuthTokens) throws {
        try save(tokens.accessToken, account: accessAccount)
        if let refresh = tokens.refreshToken {
            try save(refresh, account: refreshAccount)
        }
    }

    func load() throws -> AuthTokens? {
        guard let access = try read(account: accessAccount) else {
            return nil
        }
        let refresh = try read(account: refreshAccount)
        return AuthTokens(accessToken: access, refreshToken: refresh)
    }

    func clear() throws {
        try delete(account: accessAccount)
        try delete(account: refreshAccount)
    }
}
