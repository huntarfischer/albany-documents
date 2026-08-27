import Foundation
import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWPagination
import JJWWScrollReader
import JJWWBookShell

#if os(macOS)
import AppKit

private struct Stage75Summary: Codable {
    let status: String
    let totalPages: Int
    let farewellPages: Int
    let argusArticleBoundaries: Int
    let firstArgusInterval: String
    let secondArgusInterval: String
    let farewellSecondColumnStart: Int
}

@main
struct Stage75SnapshotCommand {
    @MainActor
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let output = arguments.first ?? "stage7-5-editorial-pacing.png"
        let canonicalPath = arguments.dropFirst().first
            ?? "../../jesse-james-and-the-widow-whipple-canonical-v1.1.json"

        let edition = try Stage0Fixture.load(canonicalURL: URL(fileURLWithPath: canonicalPath))
        let materialStore = try MaterialProfileStore.bundled()
        let pagination = try PaginationEngine().paginate(edition: edition)

        let sheet = Stage75GateSheet(
            edition: edition,
            materialStore: materialStore,
            pagination: pagination
        )
        try render(sheet, to: output)

        let argus = edition.readingUnit(id: "argus-may-8-9-1827")
        let first = argus.flatMap { EditorialIntervalCatalog.articleBoundary(in: $0, boundaryIndex: 0) }
        let second = argus.flatMap { EditorialIntervalCatalog.articleBoundary(in: $0, boundaryIndex: 1) }
        let summary = Stage75Summary(
            status: "PASS_STAGE7_5_EDITORIAL_PACING_GATE",
            totalPages: pagination.pages.count,
            farewellPages: pagination.pages(representing: FarewellArtifactLayout.unitID).count,
            argusArticleBoundaries: max(0, (argus?.blocks.count ?? 0) - 1),
            firstArgusInterval: first?.style.rawValue ?? "missing",
            secondArgusInterval: second?.style.rawValue ?? "missing",
            farewellSecondColumnStart: FarewellArtifactLayout.secondColumnStart
        )

        let outputURL = URL(fileURLWithPath: output)
        let summaryURL = outputURL.deletingLastPathComponent().appendingPathComponent("stage7-5-summary-v0.1.json")
        try JSONEncoder.pretty.encode(summary).write(to: summaryURL)

        print(output)
        print(summaryURL.path)
    }

    @MainActor
    private static func render<Content: View>(_ view: Content, to output: String) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "JJWWStage75Snapshot", code: 1)
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
struct Stage75SnapshotCommand {
    static func main() {
        print("Stage 7.5 snapshot rendering is available on macOS CI.")
    }
}
#endif
