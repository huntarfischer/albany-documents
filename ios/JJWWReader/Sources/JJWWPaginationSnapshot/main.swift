import Foundation
import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWPagination

#if os(macOS)
import AppKit

private struct Stage55Summary: Codable {
    struct UnitSummary: Codable {
        let readingUnitID: String
        let pageCount: Int
        let firstPage: Int?
        let lastPage: Int?
        let openingKind: String?
        let compositionProfileID: String?
    }

    let status: String
    let totalPages: Int
    let geometry: PageGeometry
    let units: [UnitSummary]
}

@main
struct PaginationSnapshotCommand {
    @MainActor
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let output = arguments.first ?? "page-composition-stage5-5.png"
        let canonicalPath = arguments.dropFirst().first
            ?? "../../jesse-james-and-the-widow-whipple-canonical-v1.1.json"

        let edition = try Stage0Fixture.load(canonicalURL: URL(fileURLWithPath: canonicalPath))
        let materialStore = try MaterialProfileStore.bundled()
        let engine = PaginationEngine()
        let configuration = PaginationConfiguration(
            geometry: .phonePortrait,
            textScale: .standard,
            pageCompositionProfileVersion: "page-composition-stage5.5-v0.1"
        )
        let result = try engine.paginate(edition: edition, configuration: configuration)

        try render(
            PageCompositionGateSheet(edition: edition, result: result, materialStore: materialStore),
            to: output
        )

        let outputURL = URL(fileURLWithPath: output)
        let transitionsURL = outputURL
            .deletingLastPathComponent()
            .appendingPathComponent("pagination-transitions-stage5-5.png")
        try render(
            PaginationGateSheet(edition: edition, result: result, materialStore: materialStore),
            to: transitionsURL.path
        )

        let units = edition.orderedReadingUnits.filter { $0.kind != .cover }
        let unitSummaries = units.map { unit in
            let pages = result.pages(representing: unit.id)
            return Stage55Summary.UnitSummary(
                readingUnitID: unit.id,
                pageCount: pages.count,
                firstPage: pages.first?.pageNumber,
                lastPage: pages.last?.pageNumber,
                openingKind: pages.first?.compositionKind.rawValue,
                compositionProfileID: pages.first?.compositionProfileID
            )
        }
        let summary = Stage55Summary(
            status: "PASS_PAGE_COMPOSITION_GATE",
            totalPages: result.pages.count,
            geometry: configuration.geometry,
            units: unitSummaries
        )
        let summaryData = try JSONEncoder.pretty.encode(summary)
        let summaryURL = outputURL
            .deletingLastPathComponent()
            .appendingPathComponent("page-composition-summary-stage5-5.json")
        try summaryData.write(to: summaryURL)

        let profilesURL = outputURL
            .deletingLastPathComponent()
            .appendingPathComponent("page-composition-profiles-stage5-5.json")
        try PageCompositionProfileCodec.encodeCatalog().write(to: profilesURL)

        print(output)
        print(transitionsURL.path)
        print(summaryURL.path)
        print(profilesURL.path)
        print("pages=\(result.pages.count)")
    }

    @MainActor
    private static func render<Content: View>(_ view: Content, to output: String) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "JJWWPaginationSnapshot", code: 1)
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
struct PaginationSnapshotCommand {
    static func main() {
        print("Pagination snapshot rendering is available on macOS CI.")
    }
}
#endif
