//
//  ProfileAvatarButton.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 25.07.2026.
//

import SwiftUI

struct ProfileAvatarButton: View {
    let imageURL: URL?
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            CachedAsyncImage(url: imageURL, size: 32, sizing: .fixedSquare) {
                Image(systemName: "person.crop.circle")
                    .resizable()
            }
            .clipShape(Circle())
        }
    }
}

#if DEBUG
#Preview {
    ProfileAvatarButton(imageURL: nil)
}
#endif
