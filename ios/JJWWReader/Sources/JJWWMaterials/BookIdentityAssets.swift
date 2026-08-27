import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Bundled identity artwork supplied from the current JJWW cover package.
/// The title is active cover identity. The couple is intentionally available
/// to the book shell without being inserted into ordinary reading surfaces.
public enum JJWWBookIdentityAssets {
    public static var titleArtURL: URL? {
        Bundle.module.url(forResource: "jjww-title-art", withExtension: "png")
    }

    public static var coupleCutoutURL: URL? {
        Bundle.module.url(forResource: "jjww-couple-cutout", withExtension: "png")
    }
}

public struct JJWWTitleArt: View {
    public init() {}

    public var body: some View {
        artwork
            .accessibilityLabel(Text("Jesse James and the Widow Whipple"))
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = JJWWBookIdentityAssets.titleArtURL {
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                fallback
            }
            #elseif canImport(AppKit)
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
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
        Text("JESSE JAMES\nAND THE\nWIDOW WHIPPLE")
            .font(.system(size: 30, weight: .black, design: .serif))
            .multilineTextAlignment(.center)
            .foregroundStyle(.black)
    }
}

public struct JJWWCoupleCutout: View {
    public init() {}

    public var body: some View {
        artwork
            .accessibilityLabel(Text("Couple cutout artwork"))
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = JJWWBookIdentityAssets.coupleCutoutURL {
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
            #elseif canImport(AppKit)
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
            #else
            Color.clear
            #endif
        } else {
            Color.clear
        }
    }
}
