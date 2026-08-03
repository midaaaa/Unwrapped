//
//  SpotifyAPIClient.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

protocol AccessTokenProvider: AnyObject {
    func currentAccessToken() async -> String?
    func refreshAccessToken() async throws -> String
}

actor SpotifyAPIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: AccessTokenProvider
    private let decoder: JSONDecoder

    private var nextAllowedRequestDate: Date?
    private static let minRequestInterval: TimeInterval = 0.1

    init(
        baseURL: URL = SpotifyConfig.apiBase,
        session: URLSession = .shared,
        tokenProvider: AccessTokenProvider,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        self.decoder = decoder
    }

    func request(_ endpoint: any SpotifyEndpoint, didRetry: Bool = false) async throws -> Data {
        try await performRequest(endpoint, didRetry: didRetry, emptyBodyIsSuccess: false)
    }

    func perform(_ endpoint: any SpotifyEndpoint, didRetry: Bool = false) async throws {
        _ = try await performRequest(endpoint, didRetry: didRetry, emptyBodyIsSuccess: true)
    }

    private func performRequest(_ endpoint: any SpotifyEndpoint, didRetry: Bool, emptyBodyIsSuccess: Bool) async throws -> Data {
        await throttleIfNeeded()
        let urlRequest = try await makeRequest(for: endpoint)
        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.network(underlying: URLError(.badServerResponse))
            }

            switch http.statusCode {
            case 200:
                return data
            case 204 where emptyBodyIsSuccess:
                return data
            case 204:
                throw APIError.noActivePlayback
            case 401 where !didRetry:
                _ = try await tokenProvider.refreshAccessToken()
                return try await performRequest(endpoint, didRetry: true, emptyBodyIsSuccess: emptyBodyIsSuccess)
            case 401:
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 429:
                let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
                throw APIError.rateLimited(retryAfter: retryAfter)
            case 404 where emptyBodyIsSuccess:
                throw APIError.noActiveDevice
            default:
                throw APIError.unknown(
                    statusCode: http.statusCode,
                    body: String(data: data, encoding: .utf8)
                )
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(underlying: error)
        }
    }

    func decode<T: Decodable>(_ endpoint: any SpotifyEndpoint, as type: T.Type) async throws -> T {
        let data = try await request(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(underlying: error)
        }
    }

    private func throttleIfNeeded() async {
        let now = Date()
        let earliestAllowed = nextAllowedRequestDate ?? now
        let scheduledDate = max(now, earliestAllowed)
        nextAllowedRequestDate = scheduledDate.addingTimeInterval(Self.minRequestInterval)

        let delay = scheduledDate.timeIntervalSince(now)
        guard delay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    private func makeRequest(for endpoint: any SpotifyEndpoint) async throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = endpoint.queryItems
        guard let url = components?.url else {
            throw APIError.network(underlying: URLError(.badURL))
        }

        guard let token = await tokenProvider.currentAccessToken() else {
            throw APIError.unauthorized
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
