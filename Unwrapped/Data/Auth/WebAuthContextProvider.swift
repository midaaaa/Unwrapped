//
//  WebAuthContextProvider.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import AuthenticationServices
import UIKit

@MainActor
final class WebAuthContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {

    private weak var windowScene: UIWindowScene?

    init(windowScene: UIWindowScene) {
        self.windowScene = windowScene
        super.init()
    }

    var canPresent: Bool {
        presentationWindow != nil
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let window = presentationWindow else {
            assertionFailure("WebAuth: no key window — login() should have checked canPresent")

            if let scene = windowScene {
                return UIWindow(windowScene: scene)
            }

            fatalError("WebAuth: windowScene deallocated before presentation")
        }
        return window
    }

    private var presentationWindow: UIWindow? {
        guard let scene = windowScene else { return nil }
        return scene.keyWindow ?? scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
    }
}
