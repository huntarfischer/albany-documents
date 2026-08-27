import Foundation
import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWScrollReader
import JJWWPagesReader

#if os(macOS)
import AppKit

private struct Stage6Summary: Codable {
    struct Mapping: Codable {
        let label: String
        let canonicalLine: Int
        let utf16Offset: Int
        let pageNumber: Int
        let pageStartLine: Int
    }

    let status: String
    let totalPages: Int
    let defaultTransition: String
    let reduceMotionTransition: String
    let mappings: [Mapping]
}

@main
struct PagesReaderSnapshotCommand {
    @MainActor
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let output = arguments.first ?? "pages-reader-stage6.png"
        let canonicalPath = arguments.dropFirst().first
            ?? "../../jesse-james-and-the-widow-whipple-canonical-v1.1.json"

        let edition = try Stage0Fixture.load(canonicalURL: URL(fileURLWithPath: canonicalPath))
        let materialStore = try MaterialProfileStore.bundled()
        let session = ScrollReaderSession(
            edition: edition,
            persistence: MemoryReaderLocationPersistence()
        )
        let coordinator = try ReaderLocationCoordinator(
            edition: edition,
            scrollSession: session
        )

        let requested: [(String, ReaderLocation)] = [
            (
                "ARGUS · JUSTIFIED BODY",
                ReaderLocation(
                    readingUnitID: "argus-may-8-9-1827",
                    blockID: "argus.may9.assassination",
                    canonicalLine: 15,
                    utf16OffsetInLine: 8
                )
            ),
            (
                "CONFESSION",
                ReaderLocation(
                    readingUnitID: "confession-of-jesse-james-strang",
                    blockID: "confession.primary",
                    canonicalLine: 201,
                    utf16OffsetInLine: 7
                )
            ),
            (
                "TRIAL",
                ReaderLocation(
                    readingUnitID: "trial-of-jesse-james-strang",
                    blockID: "trial.jesse",
                    canonicalLine: 450,
                    utf16OffsetInLine: 4
                )
            ),
            (
                "FAREWELL",
                ReaderLocation(
                    readingUnitID: "farewell-address",
                    blockID: "farewell.address",
                    canonicalLine: 1900,
                    utf16OffsetInLine: 2
                )
            )
        ]

        let samples: [PagesReaderGateSheet.Sample] = try requested.map { label, location in
            guard let page = coordinator.pagination.page(containing: location) else {
                throw NSError(
                    domain: "JJWWPagesReaderSnapshot",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "No PageSlice contains \(label) at line \(location.canonicalLine)"]
                )
            }
            return PagesReaderGateSheet.Sample(
                id: label,
                label: label,
                location: location,
                page: page
            )
        }

        try render(
            PagesReaderGateSheet(
                edition: edition,
                materialStore: materialStore,
                samples: samples
            ),
            to: output
        )

        let summary = Stage6Summary(
            status: "PASS_STAGE6_STATIC_PAGES_GATE",
            totalPages: coordinator.pagination.pages.count,
            defaultTransition: PageTurnPolicy.transition(reduceMotion: false).rawValue,
            reduceMotionTransition: PageTurnPolicy.transition(reduceMotion: true).rawValue,
            mappings: samples.map { sample in
                Stage6Summary.Mapping(
                    label: sample.label,
                    canonicalLine: sample.location.canonicalLine,
                    utf16Offset: sample.location.utf16OffsetInLine,
                    pageNumber: sample.page.pageNumber,
                    pageStartLine: sample.page.startLocation.canonicalLine
                )
            }
        )

        let data = try JSONEncoder.pretty.encode(summary)
        let outputURL = URL(fileURLWithPath: output)
        let summaryURL = outputURL.deletingLastPathComponent().appendingPathComponent("pages-reader-summary-stage6.json")
        try data.write(to: summaryURL)

        print(output)
        print(summaryURL.path)
        print("pages=\(coordinator.pagination.pages.count)")
    }

    @MainActor
    private static func render<Content: View>(_ view: Content, to output: String) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "JJWWPagesReaderSnapshot", code: 1)
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
struct PagesReaderSnapshotCommand {
    static func main() {
        print("Pages reader snapshot rendering is available on macOS CI.")
    }
}
#endif
