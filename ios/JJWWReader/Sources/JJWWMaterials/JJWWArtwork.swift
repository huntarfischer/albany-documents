import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private enum JJWWBundledArtwork {
    static func data(named name: String) -> Data? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "b64"),
              let encoded = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        return Data(
            base64Encoded: encoded.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

/// The supplied hand-lettered title artwork from the current JJWW cover system.
public struct JJWWTitleArtwork: View {
    public init() {}

    @ViewBuilder
    public var body: some View {
        #if canImport(UIKit)
        if let data = JJWWBundledArtwork.data(named: "jjww-title-art"),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Jesse James and the Widow Whipple")
        } else {
            fallbackTitle
        }
        #elseif canImport(AppKit)
        if let data = JJWWBundledArtwork.data(named: "jjww-title-art"),
           let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Jesse James and the Widow Whipple")
        } else {
            fallbackTitle
        }
        #else
        fallbackTitle
        #endif
    }

    private var fallbackTitle: some View {
        VStack(spacing: 3) {
            Text("JESSE JAMES")
            Text("AND THE")
            Text("WIDOW WHIPPLE")
        }
        .font(.system(size: 22, weight: .black, design: .serif))
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.black)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Jesse James and the Widow Whipple")
    }
}

/// The supplied couple cutout. It is intentionally available to the design
/// system without being placed into the reading flow by this pass.
public struct JJWWCoupleArtwork: View {
    public init() {}

    @ViewBuilder
    public var body: some View {
        #if canImport(UIKit)
        if let data = JJWWBundledArtwork.data(named: "jjww-couple-cutout"),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Couple cutout artwork")
        } else {
            Color.clear.accessibilityHidden(true)
        }
        #elseif canImport(AppKit)
        if let data = JJWWBundledArtwork.data(named: "jjww-couple-cutout"),
           let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Couple cutout artwork")
        } else {
            Color.clear.accessibilityHidden(true)
        }
        #else
        Color.clear.accessibilityHidden(true)
        #endif
    }
}
