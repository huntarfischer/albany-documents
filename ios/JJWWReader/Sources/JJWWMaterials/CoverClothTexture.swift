import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The actual orange book cloth supplied from the current JJWW cover.
///
/// This is shared material, not decorative chrome: Scroll interval reveals and
/// any later binding/overview surfaces can all expose the same physical cloth.
public struct JJWWCoverClothTexture: View {
    public let seed: UInt64

    public init(seed: UInt64 = 1827) {
        self.seed = seed
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                fallback
                texture
                    .scaleEffect(1.08)
                    .offset(x: xDrift, y: yDrift)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var texture: some View {
        if let url = Bundle.module.url(
            forResource: "jjww-cover-cloth-texture",
            withExtension: "jpeg"
        ) {
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallback
            }
            #elseif canImport(AppKit)
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallback
            }
            #else
            fallback
            #endif
        } else {
            fallback
        }
    }

    private var fallback: some View {
        Color(red: 0.91, green: 0.235, blue: 0.045)
    }

    private var xDrift: CGFloat {
        CGFloat(Int(seed % 17) - 8)
    }

    private var yDrift: CGFloat {
        CGFloat(Int((seed >> 8) % 23) - 11)
    }
}
