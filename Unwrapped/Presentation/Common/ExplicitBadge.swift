//
//  ExplicitBadge.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 26.07.2026.
//

import SwiftUI

struct ExplicitBadge: View {
    var colorScheme: ColorScheme = .light

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.65) : Color(white: 0.5)
    }

    private var letterColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        Text("E")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(letterColor)
            .frame(width: 14, height: 14)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
    }
}

extension Text {
    static func withExplicitBadge(
        _ text: String,
        colorScheme: ColorScheme,
        displayScale: CGFloat
    ) -> Text {
        let renderer = ImageRenderer(content: ExplicitBadge(colorScheme: colorScheme))
        renderer.scale = displayScale
        guard let uiImage = renderer.uiImage else { return Text(text) }
        let badge = Text(Image(uiImage: uiImage)).baselineOffset(-2)
        return Text("\(badge) \(text)")
    }
}
