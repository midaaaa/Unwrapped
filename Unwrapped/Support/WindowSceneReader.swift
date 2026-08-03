//
//  WindowSceneReader.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import SwiftUI
import UIKit

struct WindowSceneReader: UIViewRepresentable {
    @Binding var windowScene: UIWindowScene?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            windowScene = uiView.window?.windowScene
        }
    }
}
