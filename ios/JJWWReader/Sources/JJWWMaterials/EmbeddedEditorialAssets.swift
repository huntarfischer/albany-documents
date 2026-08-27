import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Shared editorial artwork derived from the supplied JJWW cover assets.
/// The title is live on the fallback cover. The couple is intentionally wired
/// but not placed in the reading flow yet.
public struct JJWWTitleArt: View {
    public let color: Color

    public init(color: Color = .white) {
        self.color = color
    }

    public var body: some View {
        EmbeddedEditorialPNG(baseName: "jjww-title-art", chunkCount: 4, template: true)
            .foregroundStyle(color)
            .accessibilityLabel("Jesse James and the Widow Whipple")
    }
}

public struct JJWWCoupleCutout: View {
    public init() {}

    public var body: some View {
        EmbeddedEditorialPNG(baseName: "jjww-couple-cutout", chunkCount: 5, template: false)
            .accessibilityHidden(true)
    }
}

private struct EmbeddedEditorialPNG: View {
    let baseName: String
    let chunkCount: Int
    let template: Bool

    var body: some View {
        Group {
            if let data = decodedData {
                platformImage(data)
            } else {
                Color.clear
            }
        }
    }

    private var decodedData: Data? {
        var encoded = ""
        for index in 0..<chunkCount {
            let suffix = String(format: "%02d", index)
            guard let url = Bundle.module.url(forResource: "\(baseName)-\(suffix)", withExtension: "b64"),
                  let chunk = try? String(contentsOf: url, encoding: .utf8) else {
                return nil
            }
            encoded += chunk.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return Data(base64Encoded: encoded)
    }

    @ViewBuilder
    private func platformImage(_ data: Data) -> some View {
        #if canImport(UIKit)
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .renderingMode(template ? .template : .original)
                .resizable()
                .scaledToFit()
        } else {
            Color.clear
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .renderingMode(template ? .template : .original)
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
