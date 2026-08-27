import Foundation
import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWPagination
import JJWWBookShell

#if os(macOS)
import AppKit

private struct Stage7Summary: Codable {
    let status: String
    let totalPages: Int
    let progressMilestones: Int
    let galleryAssetCount: Int
    let galleryMissingCount: Int
    let galleryUnplacedCount: Int
    let firstReadingLine: Int
}

@main
struct BookShellSnapshotCommand {
    @MainActor
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let output = arguments.first ?? "book-shell-stage7.png"
        let canonicalPath = arguments.dropFirst().first
            ?? "../../jesse-james-and-the-widow-whipple-canonical-v1.1.json"

        let edition = try Stage0Fixture.load(canonicalURL: URL(fileURLWithPath: canonicalPath))
        let materialStore = try MaterialProfileStore.bundled()
        let gallery = try EditorialGalleryStore.bundled()
        let pagination = try PaginationEngine().paginate(edition: edition)

        let sheet = BookShellGateSheet(
            edition: edition,
            materialStore: materialStore,
            gallery: gallery,
            pagination: pagination
        )
        try render(sheet, to: output)

        let firstReadingLine = edition.orderedReadingUnits
            .first(where: { $0.kind != .cover })?
            .canonicalAnchor.startLine ?? 0
        let summary = Stage7Summary(
            status: "PASS_STAGE7_BINDING_GATE",
            totalPages: pagination.pages.count,
            progressMilestones: ProgressSpineModel(edition: edition).milestones.count,
            galleryAssetCount: gallery.assets.count,
            galleryMissingCount: gallery.missingManifestAssets.count,
            galleryUnplacedCount: gallery.unplacedAssets.count,
            firstReadingLine: firstReadingLine
        )

        let outputURL = URL(fileURLWithPath: output)
        let summaryURL = outputURL.deletingLastPathComponent().appendingPathComponent("book-shell-summary-stage7.json")
        try JSONEncoder.pretty.encode(summary).write(to: summaryURL)

        print(output)
        print(summaryURL.path)
        print("gallery=\(gallery.assets.count) missing=\(gallery.missingManifestAssets.count)")
    }

    @MainActor
    private static func render<Content: View>(_ view: Content, to output: String) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "JJWWBookShellSnapshot", code: 1)
        }
        try png.write(to: URL(fileURLWithPath: output))
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
#else
@main
struct BookShellSnapshotCommand {
    static func main() {
        print("Stage 7 binding snapshot rendering is available on macOS CI.")
    }
}
#endif
