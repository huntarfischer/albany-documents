import Foundation
import SwiftUI
import JJWWMaterials
import JJWWTypography

#if os(macOS)
import AppKit

@main
struct TypographySpecimenCommand {
    static func main() throws {
        let output = CommandLine.arguments.dropFirst().first ?? "typography-stage3.png"
        let store = try MaterialProfileStore.bundled()
        let view = TypographySpecimenSheet(materialStore: store)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "JJWWTypographySpecimens", code: 1)
        }
        try png.write(to: URL(fileURLWithPath: output))
        print(output)
    }
}
#else
@main
struct TypographySpecimenCommand {
    static func main() {
        print("Typography specimen rendering is available on macOS CI.")
    }
}
#endif
