//
//  SpotifyTokenClient.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

struct SpotifyTokenClient {
    struct TokenResult {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int
    }

    private let clientID: String

    init(clientID: String) {
        self.clientID = clientID
    }

    func exchangeAuthorizationCode(_ code: String, verifier: String, redirectURI: String) async throws -> TokenResult {
        try await request([
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "code_verifier": verifier,
        ])
    }

    func refresh(refreshToken: String) async throws -> TokenResult {
        try await request([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID,
        ])
    }

    private func request(_ parameters: [String: String]) async throws -> TokenResult {
        var request = URLRequest(url: SpotifyConfig.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formURLEncodedData(parameters)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.tokenExchangeFailed(statusCode: -1, body: nil)
        }
        guard http.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed(
                statusCode: http.statusCode,
                body: String(data: data, encoding: .utf8)
            )
        }

        let dto = try JSONDecoder().decode(SpotifyTokenResponseDTO.self, from: data)
        return TokenResult(accessToken: dto.accessToken, refreshToken: dto.refreshToken, expiresIn: dto.expiresIn)
    }

    private func formURLEncodedData(_ parameters: [String: String]) -> Data {
        var components = URLComponents()
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        return Data(components.query!.utf8)
    }
}
