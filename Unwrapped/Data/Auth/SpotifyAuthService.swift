//
//  SpotifyAuthService.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import AuthenticationServices
import Foundation
import UIKit

protocol SpotifyAuthServiceProtocol {
    var isAuthenticated: Bool { get async }
    func login(windowScene: UIWindowScene) async throws
    func logout() throws
    func accessToken() async -> String?
    func refreshAccessToken() async throws -> String
}

@MainActor
final class SpotifyAuthService: SpotifyAuthServiceProtocol, AccessTokenProvider {
    private let clientID: String
    private let redirectURI: String
    private let scopes: String
    private let keychain: KeychainTokenStoreProtocol
    private let tokenClient: SpotifyTokenClient

    private var cachedAccessToken: String?
    private var cachedRefreshToken: String?
    private var accessTokenExpiresAt: Date?
    private var activeSession: ASWebAuthenticationSession?
    private var refreshTask: Task<String, Error>?

    init(clientID: String, redirectURI: String, scopes: String, keychain: KeychainTokenStoreProtocol) {
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scopes = scopes
        self.keychain = keychain
        self.tokenClient = SpotifyTokenClient(clientID: clientID)

        if let tokens = try? keychain.load() {
            cachedAccessToken = tokens.accessToken
            cachedRefreshToken = tokens.refreshToken
        }
    }

    var isAuthenticated: Bool {
        get async {
            cachedRefreshToken != nil
        }
    }

    func login(windowScene: UIWindowScene) async throws {
        let contextProvider = WebAuthContextProvider(windowScene: windowScene)
        guard contextProvider.canPresent else {
            throw AuthError.noPresentationAnchor
        }

        let verifier = PKCE.generateCodeVerifier()
        let challenge = PKCE.generateCodeChallenge(from: verifier)

        var authComponents = URLComponents(
            url: SpotifyConfig.authorizationEndpoint,
            resolvingAgainstBaseURL: false
        )!
        authComponents.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "scope", value: scopes),
        ]
        guard let authURL = authComponents.url else {
            throw AuthError.noAuthorizationCode
        }

        let callbackURL = try await startWebAuthSession(
            url: authURL,
            contextProvider: contextProvider
        )

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
        else {
            throw AuthError.noAuthorizationCode
        }

        let tokenResult = try await tokenClient.exchangeAuthorizationCode(code, verifier: verifier, redirectURI: redirectURI)
        try persist(tokenResult)
    }

    func logout() throws {
        try keychain.clear()
        cachedAccessToken = nil
        cachedRefreshToken = nil
        accessTokenExpiresAt = nil
    }

    func accessToken() async -> String? {
        if let expiresAt = accessTokenExpiresAt, Date() >= expiresAt {
            _ = try? await refreshAccessToken()
        }
        return cachedAccessToken
    }

    func refreshAccessToken() async throws -> String {
        if let existing = refreshTask {
            return try await existing.value
        }
        let task = Task<String, Error> {
            try await performRefresh()
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    func performRefresh() async throws -> String {
        guard let refresh = cachedRefreshToken else {
            throw AuthError.notAuthenticated
        }

        let tokenResult = try await tokenClient.refresh(refreshToken: refresh)
        try persist(tokenResult, keepExistingRefresh: tokenResult.refreshToken == nil)
        guard let accessToken = cachedAccessToken else {
            throw AuthError.notAuthenticated
        }
        return accessToken
    }

    // MARK: - AccessTokenProvider

    func currentAccessToken() async -> String? {
        await accessToken()
    }

    // MARK: - Login-flow helpers

    private var callbackURLScheme: String {
        guard let scheme = URL(string: redirectURI)?.scheme else {
            preconditionFailure("redirectURI must include a URL scheme: \(redirectURI)")
        }
        return scheme
    }

    private func startWebAuthSession(
        url: URL,
        contextProvider: WebAuthContextProvider
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            func resumeOnce(with result: Result<URL, Error>) {
                guard !didResume else { return }
                didResume = true
                switch result {
                case .success(let url):
                    continuation.resume(returning: url)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { [weak self] callbackURL, error in
                self?.activeSession = nil

                if let error {
                    if let authError = error as? ASWebAuthenticationSessionError,
                       authError.code == .canceledLogin {
                        resumeOnce(with: .failure(AuthError.userCancelled))
                    } else {
                        resumeOnce(with: .failure(error))
                    }
                    return
                }

                guard let callbackURL else {
                    resumeOnce(with: .failure(AuthError.noAuthorizationCode))
                    return
                }

                resumeOnce(with: .success(callbackURL))
            }

            session.presentationContextProvider = contextProvider
            session.prefersEphemeralWebBrowserSession = false
            activeSession = session

            guard session.start() else {
                activeSession = nil
                resumeOnce(with: .failure(AuthError.noPresentationAnchor))
                return
            }
        }
    }

    private func persist(_ result: SpotifyTokenClient.TokenResult, keepExistingRefresh: Bool = false) throws {
        cachedAccessToken = result.accessToken
        if let refreshToken = result.refreshToken {
            cachedRefreshToken = refreshToken
        } else if !keepExistingRefresh {
            cachedRefreshToken = nil
        }
        accessTokenExpiresAt = Date().addingTimeInterval(TimeInterval(result.expiresIn))

        guard let accessToken = cachedAccessToken else {
            throw AuthError.notAuthenticated
        }

        try keychain.save(AuthTokens(
            accessToken: accessToken,
            refreshToken: cachedRefreshToken
        ))
    }
}
