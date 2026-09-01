import Foundation
import Testing
import JJWWReaderCore
@testable import JJWWScrollReader

@Suite("JJWW Stage 8H Semantic Reader Roles")
struct Stage8HSemanticReaderRoleTests {
    private var repositoryRoot: URL {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let packageRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return packageRoot
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var canonicalURL: URL {
        repositoryRoot.appendingPathComponent(
            "jesse-james-and-the-widow-whipple-canonical-v1.1.json"
        )
    }

    @Test("A source the old word-list could not recognize is now identified from Layer 1")
    func eveningPostUsesSourceRegistry() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let (unit, block) = try blockPair(containing: 42, in: edition)
        let presentation = try #require(
            ReaderLineRoleResolver.presentations(for: block, in: unit)
                .first { $0.canonicalLine.number == 42 }
        )

        #expect(presentation.canonicalLine.text == "The Evening Post")
        #expect(presentation.role == .sourceHeader)
        #expect(presentation.sourceOccurrenceIDs.contains("L1-SRC-OCC-0008"))
    }

    @Test("A Layer 1 display line drives opening hierarchy without re-parsing capitalization")
    func proclamationUsesStructuralIndex() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let (unit, block) = try blockPair(containing: 26, in: edition)
        let presentation = try #require(
            ReaderLineRoleResolver.presentations(for: block, in: unit)
                .first { $0.canonicalLine.number == 26 }
        )

        #expect(presentation.canonicalLine.text == "PROCLAMATION")
        #expect(presentation.role == .sectionTitle)
        #expect(presentation.semanticTypes.contains("uppercase_display_line"))
    }

    @Test("An explicit procedural label no longer has to match the old counsel word-list")
    func proceduralLabelUsesStructuralIndex() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let (unit, block) = try blockPair(containing: 924, in: edition)
        let presentation = try #require(
            ReaderLineRoleResolver.presentations(for: block, in: unit)
                .first { $0.canonicalLine.number == 924 }
        )

        #expect(presentation.canonicalLine.text == "Cross examined by Williams.")
        #expect(presentation.role == .counselLabel)
        #expect(presentation.semanticTypes.contains("procedural_or_speaker_label"))
    }

    @Test("Legacy fixture blocks without Layer 1 semantics still retain their fallback reader contract")
    func legacyFixtureKeepsFallbackContract() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let argus = try #require(edition.readingUnit(id: "argus-may-8-9-1827"))
        let block = try #require(argus.blocks.first)
        let roles = ReaderLineRoleResolver.presentations(for: block, in: argus).map(\.role)

        #expect(roles.contains(.dateHeading))
        #expect(roles.contains(.sourceHeader))
        #expect(roles.contains(.sectionTitle))
    }

    private func blockPair(
        containing line: Int,
        in edition: Edition
    ) throws -> (ReadingUnit, DocumentBlock) {
        for unit in edition.orderedReadingUnits {
            if let block = unit.blocks.first(where: { $0.canonicalAnchor.contains(line: line) }) {
                return (unit, block)
            }
        }
        throw MissingBlock(line: line)
    }

    private struct MissingBlock: Error {
        let line: Int
    }
}
