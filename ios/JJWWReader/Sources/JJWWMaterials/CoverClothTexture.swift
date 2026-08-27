import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The actual orange book cloth supplied from the current JJWW cover.
///
/// This is shared material, not decorative chrome: Scroll interval reveals and
/// later binding/overview surfaces expose the same physical cloth. The bundled
/// crop is tiled and modestly enlarged so the weave remains legible at phone scale.
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
                    .padding(-42)
                    .scaleEffect(1.72)
                    .offset(x: xDrift, y: yDrift)
                    .contrast(1.16)
                    .saturation(1.04)
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
                    .resizable(resizingMode: .tile)
                    .interpolation(.high)
            } else {
                fallback
            }
            #elseif canImport(AppKit)
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable(resizingMode: .tile)
                    .interpolation(.high)
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
