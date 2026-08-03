//
//  AlbumBackgroundRenderer.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 24.07.2026.
//

import CoreImage
import UIKit

nonisolated enum AlbumBackgroundRenderer {
    private static let context = CIContext()

    static func blurredExpanded(
        from image: UIImage,
        radius: CGFloat = 60,
        expansion: CGFloat = 1.5,
        downsampleSize: CGFloat = 100
    ) -> UIImage? {
        guard let sourceImage = CIImage(image: image) else { return nil }

        let scale = min(1, downsampleSize / max(sourceImage.extent.width, sourceImage.extent.height))
        let ciImage = scale < 1 ? sourceImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale)) : sourceImage
        let scaledRadius = radius * scale

        guard let clampFilter = CIFilter(name: "CIAffineClamp") else { return nil }
        clampFilter.setValue(ciImage, forKey: kCIInputImageKey)
        clampFilter.setValue(CGAffineTransform.identity, forKey: kCIInputTransformKey)
        guard let clamped = clampFilter.outputImage else { return nil }

        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
        blurFilter.setValue(clamped, forKey: kCIInputImageKey)
        blurFilter.setValue(scaledRadius, forKey: kCIInputRadiusKey)
        guard let blurred = blurFilter.outputImage else { return nil }

        let extent = ciImage.extent
        let expandedExtent = extent.insetBy(
            dx: -extent.width * (expansion - 1) / 2,
            dy: -extent.height * (expansion - 1) / 2
        )

        guard let cgImage = context.createCGImage(blurred, from: expandedExtent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
