//
//  SpotifyLoginController.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import SwiftUI

@MainActor
@Observable
final class SpotifyLoginController {
    var windowScene: UIWindowScene?
    private(set) var isLoggingIn = false
    var errorMessage: String?

    var canLogin: Bool { !isLoggingIn && windowScene != nil }

    func login(authService: SpotifyAuthServiceProtocol?, onSuccess: () -> Void) async {
        guard let authService, let windowScene else { return }

        isLoggingIn = true
        errorMessage = nil
        defer { isLoggingIn = false }

        do {
            try await authService.login(windowScene: windowScene)
            onSuccess()
        } catch AuthError.userCancelled {
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
