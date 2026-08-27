import Foundation
import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWPagination

#if os(macOS)
import AppKit

private struct Stage5Summary: Codable {
    struct UnitSummary: Codable {
        let readingUnitID: String
        let pageCount: Int
        let firstPage: Int?
        let lastPage: Int?
    }

    let status: String
    let totalPages: Int
    let geometry: PageGeometry
    let units: [UnitSummary]
    let transitionPairs: [[Int]]
}

@main
struct PaginationSnapshotCommand {
    @MainActor
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let output = arguments.first ?? "pagination-transitions-stage5.png"
        let canonicalPath = arguments.dropFirst().first
            ?? "../../jesse-james-and-the-widow-whipple-canonical-v1.1.json"

        let edition = try Stage0Fixture.load(canonicalURL: URL(fileURLWithPath: canonicalPath))
        let materialStore = try MaterialProfileStore.bundled()
        let engine = PaginationEngine()
        let configuration = PaginationConfiguration(
            geometry: .phonePortrait,
            textScale: .standard
        )
        let result = try engine.paginate(edition: edition, configuration: configuration)

        try render(
            PaginationGateSheet(edition: edition, result: result, materialStore: materialStore),
            to: output
        )

        let units = edition.orderedReadingUnits.filter { $0.kind != .cover }
        let unitSummaries = units.map { unit in
            let pages = result.pages(representing: unit.id)
            return Stage5Summary.UnitSummary(
                readingUnitID: unit.id,
                pageCount: pages.count,
                firstPage: pages.first?.pageNumber,
                lastPage: pages.last?.pageNumber
            )
        }
        var transitions: [[Int]] = []
        if units.count >= 2 {
            for index in 0..<(units.count - 1) {
                if let left = result.pages(representing: units[index].id).last?.pageNumber,
                   let right = result.pages(representing: units[index + 1].id).first?.pageNumber {
                    transitions.append([left, right])
                }
            }
        }
        let summary = Stage5Summary(
            status: "PASS_STATIC_PAGINATION_GATE",
            totalPages: result.pages.count,
            geometry: configuration.geometry,
            units: unitSummaries,
            transitionPairs: transitions
        )
        let data = try JSONEncoder.pretty.encode(summary)
        let outputURL = URL(fileURLWithPath: output)
        let summaryURL = outputURL.deletingLastPathComponent().appendingPathComponent("pagination-summary-stage5.json")
        try data.write(to: summaryURL)

        print(output)
        print(summaryURL.path)
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
