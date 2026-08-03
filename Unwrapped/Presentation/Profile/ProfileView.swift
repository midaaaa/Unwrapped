//
//  ProfileView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    var isAuthenticated: Bool = true
    var authService: SpotifyAuthServiceProtocol?
    var onLoginSuccess: () -> Void = {}
    var onLogout: () -> Void
    var onDataDeleted: () -> Void = {}

    @AppStorage(AppSettingsKeys.rulerHapticFeedback) private var isRulerHapticFeedbackEnabled = true
    @AppStorage(AppSettingsKeys.activeCardWindowSeconds) private var activeCardWindowSeconds = 3
    @AppStorage(AppSettingsKeys.hasSeenOnboarding) private var hasSeenOnboarding = false

    @State private var isShowingDeleteAllConfirmation = false
    @State private var isShowingLogoutConfirmation = false
    @State private var loginController = SpotifyLoginController()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if !isAuthenticated {
                        signInRow
                    } else if let profile = viewModel.profile {
                        HStack(spacing: 14) {
                            CachedAsyncImage(url: profile.imageURL, size: 60, sizing: .fixedSquare) {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .foregroundStyle(.secondary)
                            }
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.displayName)
                                    .font(.title3.bold())
                                HStack(spacing: 12) {
                                    if let country = profile.country {
                                        Label(country, systemImage: "globe")
                                    }
                                    Label(profile.product.rawValue.capitalized, systemImage: "sparkles")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Couldn't load profile")
                                .font(.subheadline.weight(.medium))
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ProgressView()
                    }
                }

                Section("Settings") {
                    Toggle("Haptic feedback in seconds picker", isOn: $isRulerHapticFeedbackEnabled)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Active card window")
                            Spacer()
                            Text(Measurement(value: Double(activeCardWindowSeconds), unit: UnitDuration.seconds).formatted(.measurement(width: .narrow)))
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(activeCardWindowSeconds) },
                                set: { activeCardWindowSeconds = Int($0) }
                            ),
                            in: 1...5,
                            step: 1
                        ) {
                            Text("Active card window")
                        } minimumValueLabel: {
                            Image(systemName: "hare")
                        } maximumValueLabel: {
                            Image(systemName: "tortoise")
                        }
                    }

                    Button {
                        hasSeenOnboarding = false
                    } label: {
                        HStack {
                            Text("Show onboarding again")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Language")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(currentLanguageName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Section("Storage") {
                    Menu {
                        Button {
                            Task { await viewModel.clearCache() }
                        } label: {
                            Label("Clear Cache", systemImage: "arrow.3.trianglepath")
                        }

                        Button(role: .destructive) {
                            isShowingDeleteAllConfirmation = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash")
                        }

                        #if DEBUG
                        Button {
                            Task {
                                await viewModel.seedRandomEntries()
                                onDataDeleted()
                            }
                        } label: {
                            Label("Seed Random Entries (Debug)", systemImage: "shuffle")
                        }
                        #endif
                    } label: {
                        Label("Manage Storage", systemImage: "internaldrive")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if isAuthenticated {
                    Section {
                        Button("Logout", role: .destructive) {
                            isShowingLogoutConfirmation = true
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .listRowInsets(EdgeInsets())
                        .glassEffect()
                    }
                }
            }
            .navigationTitle("Profile")
            .background(WindowSceneReader(windowScene: $loginController.windowScene))
            .task(id: isAuthenticated) {
                guard isAuthenticated else { return }
                await viewModel.load()
            }
            .alert("Delete All Data?", isPresented: $isShowingDeleteAllConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteAllData()
                        onDataDeleted()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes every diary entry and taste snapshot. This can't be undone.")
            }
            .alert("Log Out?", isPresented: $isShowingLogoutConfirmation) {
                Button("Log Out", role: .destructive, action: onLogout)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in with Spotify again to continue.")
            }
            .errorAlert("Storage Error", message: $viewModel.storageErrorMessage)
        }
    }

    private var currentLanguageName: String {
        guard let languageCode = Locale.current.language.languageCode?.identifier else {
            return Locale.current.identifier
        }
        return Locale.current.localizedString(forLanguageCode: languageCode)?.capitalized
            ?? languageCode
    }

    @ViewBuilder
    private var signInRow: some View {
        Button {
            Task { await loginController.login(authService: authService, onSuccess: onLoginSuccess) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sign in with Spotify")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("Required to log tracks and see your recently played")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                if loginController.isLoggingIn {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!loginController.canLogin)

        if let errorMessage = loginController.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}

#if DEBUG
#Preview("Signed In") {
    ProfileView(viewModel: .preview(), onLogout: {})
}

#Preview("Signed Out") {
    ProfileView(
        viewModel: .preview(),
        isAuthenticated: false,
        authService: PreviewSpotifyAuthService(),
        onLogout: {}
    )
}
#endif
