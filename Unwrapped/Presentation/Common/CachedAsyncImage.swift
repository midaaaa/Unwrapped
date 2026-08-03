//
//  CachedAsyncImage.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import SwiftUI

private let cachedImagePlaceholderDelay: Duration = .milliseconds(150)

@MainActor
final class ImageMemoryCache {
    static let shared = ImageMemoryCache()
    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func store(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
    func clear() { cache.removeAllObjects() }
}

enum CachedImageSizing {
    case adaptiveAspect
    case fixedSquare
}

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let size: CGFloat
    var maxWidth: CGFloat? = nil
    var sizing: CachedImageSizing = .adaptiveAspect
    @ViewBuilder var placeholder: () -> Placeholder
    var onLoad: ((UIImage?) -> Void)?

    @State private var uiImage: UIImage?
    @State private var loadedURL: URL?
    @State private var showPlaceholder = false

    var body: some View {
        Group {
            if let uiImage, !showPlaceholder {
                switch sizing {
                case .adaptiveAspect:
                    let fitted = fittedSize(for: uiImage)
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: fitted.width, height: fitted.height)
                case .fixedSquare:
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                }
            } else {
                placeholder()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: size, height: size)
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func fittedSize(for uiImage: UIImage) -> CGSize {
        let pixelSize = uiImage.size
        guard pixelSize.height > 0 else { return CGSize(width: size, height: size) }
        let aspect = pixelSize.width / pixelSize.height

        let idealWidth = size * aspect
        guard let maxWidth, idealWidth > maxWidth else {
            return CGSize(width: idealWidth, height: size)
        }
        return CGSize(width: maxWidth, height: maxWidth / aspect)
    }

    private func load() async {
        guard let url else {
            uiImage = nil
            loadedURL = nil
            showPlaceholder = false
            onLoad?(nil)
            return
        }
        if let cached = ImageMemoryCache.shared.image(for: url) {
            showPlaceholder = false
            uiImage = cached
            loadedURL = url
            onLoad?(cached)
            return
        }

        showPlaceholder = false

        async let delayedPlaceholder: Void = { @MainActor in
            try? await Task.sleep(for: cachedImagePlaceholderDelay)
            if !Task.isCancelled, loadedURL != url {
                showPlaceholder = true
                onLoad?(nil)
            }
        }()

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else {
            await delayedPlaceholder
            return
        }
        ImageMemoryCache.shared.store(image, for: url)
        uiImage = image
        loadedURL = url
        showPlaceholder = false
        onLoad?(image)
        await delayedPlaceholder
    }
}
