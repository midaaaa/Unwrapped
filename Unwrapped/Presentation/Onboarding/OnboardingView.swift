//
//  OnboardingView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 01.08.2026.
//

import SwiftUI

private struct OnboardingFeature: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

struct OnboardingView: View {
    var authService: SpotifyAuthServiceProtocol?
    var onLoginSuccess: () -> Void = {}
    var onDismiss: () -> Void = {}

    @State private var loginController = SpotifyLoginController()

    private let features: [OnboardingFeature] = [
        OnboardingFeature(
            systemImage: "music.note.list",
            title: "Your music diary",
            description: "Log tracks as you listen — a quick reaction or a detailed note, whichever fits the moment."
        ),
        OnboardingFeature(
            systemImage: "waveform.path.ecg",
            title: "See your listening timeline",
            description: "Every entry lines up against the track's own timeline, right where you logged it."
        ),
        OnboardingFeature(
            systemImage: "chart.bar.xaxis",
            title: "Discover your patterns",
            description: "Moods, streaks, and how your taste changes over time — all in one Stats tab."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 16) {
                        AppIconImage()

                        Text("Welcome to Unwrapped")
                            .font(.largeTitle.bold())
                    }

                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(features) { feature in
                            featureRow(feature)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if let errorMessage = loginController.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await loginController.login(authService: authService, onSuccess: onLoginSuccess) }
                    } label: {
                        ZStack {
                            Text("Sign in with Spotify")
                                .opacity(loginController.isLoggingIn ? 0 : 1)
                            if loginController.isLoggingIn {
                                ProgressView()
                            }
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(!loginController.canLogin)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .background(WindowSceneReader(windowScene: $loginController.windowScene))
    }

    private func featureRow(_ feature: OnboardingFeature) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

}

#if DEBUG
#Preview {
    OnboardingView(authService: PreviewSpotifyAuthService())
}
#endif
