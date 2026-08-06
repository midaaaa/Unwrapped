//
//  AppIconImage.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 06.08.2026.
//

import SwiftUI

struct AppIconImage: View {
    var size: CGFloat = 72

    var body: some View {
        Image("AppIconHighRes")
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .frame(width: size, height: size)
    }
}
