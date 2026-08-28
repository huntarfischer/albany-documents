import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The actual orange book cloth supplied from the current JJWW cover.
///
/// Stage 7.5a treats this as the continuous reading table underneath the papers.
/// The bundled 128 px crop is tiled at near-native scale so the weave remains
/// visibly cloth rather than collapsing into a flat orange fill.
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
                    .offset(x: xDrift, y: yDrift)
                    .contrast(1.06)
                    .saturation(1.03)
                Color.black.opacity(0.018)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var texture: some View {
        if let url = Bundle.module.url(
            forResource: "jjww-cover-cloth-tile-128",
            withExtension: "jpg"
        ) {
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable(resizingMode: .tile)
                    .interpolation(.medium)
            } else {
                fallback
            }
            #elseif canImport(AppKit)
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable(resizingMode: .tile)
                    .interpolation(.medium)
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
