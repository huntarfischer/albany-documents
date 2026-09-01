import Foundation
import Testing
@testable import JJWWReaderCore

@Suite("JJWW Stage 8H Layer 1 Semantic Plumbing")
struct Stage8HSemanticPlumbingTests {
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

    @Test("The sealed Layer 1 structure and source registry load at their full counts")
    func fullLayer1SemanticCountsLoad() throws {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let semantics = try Stage8Layer1Semantics.load(ownership: ownership)

        #expect(semantics.structuralSpans.count == 468)
        #expect(semantics.sourceOccurrences.count == 82)
        #expect(semantics.sourceContexts.count == 44)
        #expect(Set(semantics.structuralSpans.map(\.id)).count == 468)
        #expect(Set(semantics.sourceOccurrences.map(\.source.id)).count == 67)
    }

    @Test("The one v1.1 compiler correction rebases semantic labels without changing geometry")
    func semanticLabelRebasePreservesCanonicalGeometry() throws {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let semantics = try Stage8Layer1Semantics.load(ownership: ownership)
        let correctedDate = try #require(semantics.structuralSpans.first {
            $0.type == "dated_item" && $0.canonicalAnchor.startLine == 119
        })
        let canonicalLine = try #require(ownership.lines.first { $0.number == 119 })

        #expect(correctedDate.labelAsWritten == "Monday June 18, 1827")
        #expect(correctedDate.canonicalAnchor.startLine == 119)
        #expect(canonicalLine.text == "Monday June 18, 1827")
    }

    @Test("Production DocumentBlocks now carry exact Layer 1 structure and source identity")
    func productionBlocksCarryLayer1Semantics() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let block = try #require(edition.orderedReadingUnits
            .flatMap(\.blocks)
            .first { $0.canonicalAnchor.contains(line: 42) })
        let source = try #require(block.sourceOccurrences.first {
            $0.attributionAnchor.contains(line: 42)
        })

        #expect(source.id == "L1-SRC-OCC-0008")
        #expect(source.role == "direct_attribution")
        #expect(source.source.id == "L1-SRC-0003")
        #expect(source.source.titleAsWritten == "The Evening Post")
        #expect(source.source.sourceType == "periodical")
        #expect(block.semanticSpans.contains {
            $0.type == "dated_item" && $0.canonicalAnchor.startLine == 41
        })
    }

    @Test("Layer 1 distinctions survive instead of promoting acknowledgments into source claims")
    func attributionRolesRemainDistinct() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let block = try #require(edition.orderedReadingUnits
            .flatMap(\.blocks)
            .first { $0.canonicalAnchor.contains(line: 62) })

        #expect(block.sourceOccurrences.contains {
            $0.role == "archive_acknowledgment" &&
            $0.source.titleAsWritten == "Historic Cherry Hill"
        })
        #expect(block.sourceOccurrences.contains {
            $0.role == "direct_attribution" &&
            $0.source.titleAsWritten == "The Albany Argus & City Gazette,"
        })
    }

    @Test("Overlapping Layer 1 structures remain available inside the production ownership blocks")
    func overlappingStructureSurvives() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let witnessBlock = try #require(edition.orderedReadingUnits
            .flatMap(\.blocks)
            .first { $0.canonicalAnchor.contains(line: 284) })
        let proceduralBlock = try #require(edition.orderedReadingUnits
            .flatMap(\.blocks)
            .first { $0.canonicalAnchor.contains(line: 924) })

        #expect(witnessBlock.semanticSpans.contains {
            $0.type == "witness_testimony_segment" && $0.canonicalAnchor.startLine == 284
        })
        #expect(proceduralBlock.semanticSpans.contains {
            $0.type == "procedural_or_speaker_label" && $0.canonicalAnchor.startLine == 924
        })
    }
}
