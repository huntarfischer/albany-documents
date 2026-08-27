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
    public static var titleArtData: Data? {
        decodedResource(named: "jjww-title-art")
    }

    public static var coupleCutoutData: Data? {
        decodedResource(named: "jjww-couple-cutout")
    }

    private static func decodedResource(named name: String) -> Data? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "b64"),
              let encoded = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        return Data(
            base64Encoded: encoded.trimmingCharacters(in: .whitespacesAndNewlines)
        )
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
        #if canImport(UIKit)
        if let data = JJWWBookIdentityAssets.titleArtData,
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            fallback
        }
        #elseif canImport(AppKit)
        if let data = JJWWBookIdentityAssets.titleArtData,
           let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            fallback
        }
        #else
        fallback
        #endif
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
        #if canImport(UIKit)
        if let data = JJWWBookIdentityAssets.coupleCutoutData,
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Color.clear
        }
        #elseif canImport(AppKit)
        if let data = JJWWBookIdentityAssets.coupleCutoutData,
           let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Color.clear
        }
        #else
        Color.clear
        #endif
    }
}
