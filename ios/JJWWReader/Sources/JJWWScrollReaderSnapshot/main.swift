import Foundation
import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWScrollReader

#if os(macOS)
import AppKit

@main
struct ScrollReaderSnapshotCommand {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let output = arguments.first ?? "scroll-reader-stage4.png"
        let canonicalPath = arguments.dropFirst().first
            ?? "../../jesse-james-and-the-widow-whipple-canonical-v1.1.json"

        let edition = try Stage0Fixture.load(
            canonicalURL: URL(fileURLWithPath: canonicalPath)
        )
        let materialStore = try MaterialProfileStore.bundled()
        let view = ScrollReaderGateSheet(
            edition: edition,
            materialStore: materialStore
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "JJWWScrollReaderSnapshot", code: 1)
        }

        try png.write(to: URL(fileURLWithPath: output))
        print(output)
    }
}
#else
@main
struct ScrollReaderSnapshotCommand {
    static func main() {
        print("Scroll reader snapshot rendering is available on macOS CI.")
    }
}
#endif
