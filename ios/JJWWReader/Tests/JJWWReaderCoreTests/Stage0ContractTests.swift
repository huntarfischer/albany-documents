import Foundation
import Testing
@testable import JJWWReaderCore

@Suite("JJWW Reader Stage 0 Contract")
struct Stage0ContractTests {
    private let expectedUnitIDs = [
        "cover",
        "argus-may-8-9-1827",
        "daily-advertiser-june-18-1827",
        "confession-of-jesse-james-strang",
        "trial-of-jesse-james-strang",
        "farewell-address"
    ]

    private let expectedRanges = [
        ReadingAnchor(canonicalLayer0Version: "1.1", startLine: 1, endLine: 5),
        ReadingAnchor(canonicalLayer0Version: "1.1", startLine: 6, endLine: 23),
        ReadingAnchor(canonicalLayer0Version: "1.1", startLine: 119, endLine: 127),
        ReadingAnchor(canonicalLayer0Version: "1.1", startLine: 173, endLine: 228),
        ReadingAnchor(canonicalLayer0Version: "1.1", startLine: 229, endLine: 584),
        ReadingAnchor(canonicalLayer0Version: "1.1", startLine: 1892, endLine: 1958)
    ]

    private var canonicalURL: URL {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let packageRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let repositoryRoot = packageRoot
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        return repositoryRoot.appendingPathComponent(
            "jesse-james-and-the-widow-whipple-canonical.json"
        )
    }

    @Test("Fixture order exactly matches the authored preliminary sequence")
    func authoredOrder() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)

        #expect(edition.orderedReadingUnits.map(\.id) == expectedUnitIDs)
        #expect(edition.orderedReadingUnits.map(\.sequence) == Array(0...5))
        #expect(edition.orderedReadingUnits.map(\.canonicalAnchor) == expectedRanges)
    }

    @Test("Every ReadingUnit and DocumentBlock has a stable canonical anchor")
    func stableAnchors() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)

        #expect(edition.canonicalLayer0Version == "1.1")
        #expect(edition.canonicalLineSequenceSHA256 == "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e")

        for unit in edition.readingUnits {
            #expect(unit.canonicalAnchor.startLine > 0)
            #expect(unit.canonicalAnchor.endLine >= unit.canonicalAnchor.startLine)
            #expect(unit.canonicalAnchor.canonicalLayer0Version == edition.canonicalLayer0Version)
            #expect(!unit.blocks.isEmpty)

            let blockLineNumbers = unit.blocks.flatMap(\.lines).map(\.number)
            #expect(blockLineNumbers.first == unit.canonicalAnchor.startLine)
            #expect(blockLineNumbers.last == unit.canonicalAnchor.endLine)

            for block in unit.blocks {
                #expect(block.canonicalAnchor.startLine > 0)
                #expect(block.canonicalAnchor.endLine >= block.canonicalAnchor.startLine)
                #expect(block.lines.first?.number == block.canonicalAnchor.startLine)
                #expect(block.lines.last?.number == block.canonicalAnchor.endLine)

                let expectedNumbers = Array(block.canonicalAnchor.startLine...block.canonicalAnchor.endLine)
                #expect(block.lines.map(\.number) == expectedNumbers)
            }
        }
    }

    @Test("Lookup by stable ID and immutable sequence is deterministic")
    func deterministicLookup() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)

        for unit in edition.readingUnits {
            #expect(edition.readingUnit(id: unit.id) == unit)
            #expect(edition.readingUnit(sequence: unit.sequence) == unit)
        }

        #expect(edition.readingUnit(id: "does-not-exist") == nil)
        #expect(edition.readingUnit(sequence: 999) == nil)
    }

    @Test("The fixture builds the current v1.1 selected canonical text")
    func plainTextGate() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let selectedLines = edition.orderedReadingUnits.flatMap(\.blocks).flatMap(\.lines)

        #expect(selectedLines.count == 511)
        #expect(selectedLines.first?.number == 1)
        #expect(selectedLines.first?.text == "[ Image: LOGO BLACK.png ]")
        #expect(selectedLines.last?.number == 1958)
        #expect(selectedLines.last?.text == "And bid thee go and sin NO more.")

        let june18 = try #require(
            edition.readingUnit(id: "daily-advertiser-june-18-1827")
        )
        #expect(june18.canonicalText.hasPrefix("Monday June 18, 1827"))
    }

    @Test("Stage 0 contains no SwiftUI view layer")
    func noViewLayerYet() throws {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let packageRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceRoot = packageRoot.appendingPathComponent("Sources/JJWWReaderCore")

        let enumerator = FileManager.default.enumerator(
            at: sourceRoot,
            includingPropertiesForKeys: nil
        )

        var swiftFiles: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            if url.pathExtension == "swift" {
                swiftFiles.append(url)
            }
        }

        #expect(!swiftFiles.isEmpty)

        for file in swiftFiles {
            let source = try String(contentsOf: file, encoding: .utf8)
            #expect(!source.contains("import SwiftUI"))
            #expect(!source.contains(": View"))
        }
    }
}
