//
//  View+StableWidth.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 26.07.2026.
//

import SwiftUI

extension View {
    func stableFullWidth() -> some View {
        frame(maxWidth: .infinity)
    }
}
