//
//  DismissAttemptDetector.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 26.07.2026.
//

import SwiftUI
import UIKit

struct DismissAttemptDetector: UIViewControllerRepresentable {
    let onAttempt: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onAttempt: onAttempt)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.onAttempt = onAttempt
        DispatchQueue.main.async {
            uiViewController.parent?.presentationController?.delegate = context.coordinator
        }
    }

    final class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var onAttempt: () -> Void
        init(onAttempt: @escaping () -> Void) {
            self.onAttempt = onAttempt
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            onAttempt()
        }
    }
}
