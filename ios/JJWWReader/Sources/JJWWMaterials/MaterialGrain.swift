import Foundation
import CoreGraphics
import CoreImage

public enum DeterministicGrainField {
    public static func bytes(seed: UInt64, width: Int, height: Int) -> [UInt8] {
        guard width > 0, height > 0 else { return [] }
        var rng = SplitMix64(seed: seed)
        return (0..<(width * height)).map { _ in UInt8(truncatingIfNeeded: rng.next() >> 56) }
    }
}

public final class MaterialGrainCache: @unchecked Sendable {
    public static let shared = MaterialGrainCache()

    private final class Box: NSObject {
        let image: CGImage
        init(_ image: CGImage) { self.image = image }
    }

    private let cache = NSCache<NSString, Box>()
    private let context = CIContext(options: [.cacheIntermediates: true])

    private init() {
        cache.countLimit = 48
    }

    public func image(for recipe: GrainRecipe) -> CGImage? {
        guard recipe.enabled, recipe.resolution > 0 else { return nil }
        let key = "\(recipe.seed)-\(recipe.resolution)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached.image
        }

        let resolution = recipe.resolution
        let bytes = DeterministicGrainField.bytes(seed: recipe.seed, width: resolution, height: resolution)
        let data = Data(bytes) as CFData
        guard let provider = CGDataProvider(data: data) else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let base = CGImage(
            width: resolution,
            height: resolution,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: resolution,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else { return nil }

        let input = CIImage(cgImage: base)
        let processed = input
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 0.35])
            .cropped(to: input.extent)

        guard let output = context.createCGImage(processed, from: input.extent) else { return nil }
        cache.setObject(Box(output), forKey: key)
        return output
    }
}
