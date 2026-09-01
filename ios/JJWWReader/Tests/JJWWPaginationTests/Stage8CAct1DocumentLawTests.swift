import Foundation
import Testing
import JJWWReaderCore
@testable import JJWWPagination

@Suite("JJWW Stage 8C Act I Documentary Break Law")
struct Stage8CAct1DocumentLawTests {
    private var canonicalURL: URL {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let packageRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let repositoryRoot = packageRoot
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return repositoryRoot.appendingPathComponent(
            "jesse-james-and-the-widow-whipple-canonical-v1.1.json"
        )
    }

    @Test("Act I freezes the accepted A and B structural floor")
    @MainActor
    func acceptedFloorRemainsExact() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let semantics = try Stage8Layer1Semantics.load(ownership: ownership)
        let inventory = DocumentPaginationLaw.inventory(in: edition)

        #expect(edition.canonicalLineSequenceSHA256 == "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e")
        #expect(edition.orderedReadingUnits.count == 75)
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).count == 82)
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).flatMap(\.lines).count == 2_069)
        #expect(ownership.containers.count == 82)
        #expect(semantics.structuralSpans.count == 468)
        #expect(semantics.sourceOccurrences.count == 82)
        #expect(semantics.sourceContexts.count == 44)
        #expect(inventory.uniqueStructuralSpanCount == 468)
        #expect(inventory.uniqueSourceOccurrenceCount == 82)
        #expect(inventory.uniqueSourceContextCount == 44)
    }

    @Test("Act I inventories the documentary evidence already present in Layer 1")
    @MainActor
    func documentaryEvidenceInventory() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let inventory = DocumentPaginationLaw.inventory(in: edition)

        for semanticType in [
            "dated_item",
            "uppercase_display_line",
            "witness_testimony_segment",
            "procedural_or_speaker_label",
            "image_placeholder"
        ] {
            #expect((inventory.semanticTypeCounts[semanticType] ?? 0) > 0)
        }
        #expect(!inventory.sourceTypeCounts.isEmpty)
        #expect(!inventory.sourceRelationshipCounts.isEmpty)
    }

    @Test("Document identity is independent of a shared visual family")
    @MainActor
    func documentIdentityIsNotVisualFamily() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let albany = try unitAndBlock(containing: 34, in: edition)
        let poughkeepsie = try unitAndBlock(containing: 37, in: edition)

        #expect(albany.unit.typographyProfile == poughkeepsie.unit.typographyProfile)
        #expect(albany.unit.materialProfile == poughkeepsie.unit.materialProfile)

        let albanyIdentity = DocumentPaginationLaw.documentIdentity(
            for: 34,
            in: albany.block
        )
        let poughkeepsieIdentity = DocumentPaginationLaw.documentIdentity(
            for: 37,
            in: poughkeepsie.block
        )

        #expect(albanyIdentity.basis == .structuralSpan)
        #expect(poughkeepsieIdentity.basis == .structuralSpan)
        #expect(albanyIdentity.structuralType == "dated_item")
        #expect(poughkeepsieIdentity.structuralType == "dated_item")
        #expect(albanyIdentity.id != poughkeepsieIdentity.id)
    }

    @Test("The most specific nested documentary object outranks its broader container")
    @MainActor
    func nestedDocumentIdentityWins() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let outer = try unitAndBlock(containing: 1_172, in: edition)
        let nested = try unitAndBlock(containing: 1_174, in: edition)
        #expect(outer.block.id == nested.block.id)

        let outerEvidence = DocumentPaginationLaw.evidence(
            for: 1_172,
            in: outer.block
        )
        let nestedEvidence = DocumentPaginationLaw.evidence(
            for: 1_174,
            in: nested.block
        )
        let nestedBody = DocumentPaginationLaw.evidence(
            for: 1_175,
            in: nested.block
        )

        #expect(outerEvidence.documentIdentity.structuralType == "dated_item")
        #expect(nestedEvidence.documentIdentity.structuralType == "request_document")
        #expect(nestedEvidence.beginsDocument)
        #expect(nestedEvidence.documentIdentity.id == nestedBody.documentIdentity.id)
        #expect(outerEvidence.documentIdentity.id != nestedEvidence.documentIdentity.id)
    }

    @Test("Direct source attribution remains explicit evidence rather than a word-list guess")
    @MainActor
    func directSourceEvidenceSurvives() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let albany = try unitAndBlock(containing: 35, in: edition)
        let poughkeepsie = try unitAndBlock(containing: 38, in: edition)

        let albanyEvidence = DocumentPaginationLaw.evidence(for: 35, in: albany.block)
        let poughkeepsieEvidence = DocumentPaginationLaw.evidence(for: 38, in: poughkeepsie.block)

        #expect(albanyEvidence.beginsDirectSourceAttribution)
        #expect(poughkeepsieEvidence.beginsDirectSourceAttribution)
        #expect(!albanyEvidence.sourceOccurrenceIDs.isEmpty)
        #expect(!poughkeepsieEvidence.sourceOccurrenceIDs.isEmpty)
        #expect(albanyEvidence.sourceOccurrenceIDs != poughkeepsieEvidence.sourceOccurrenceIDs)
    }

    @Test("Act I exposes exactly the four approved break dispositions")
    func breakVocabularyIsSmallAndStable() {
        #expect(DocumentBreakDisposition.allCases == [.preferred, .allowed, .avoid, .keep])
        #expect(DocumentPaginationLaw.version == "stage8c-act1-document-law-v0.1")
    }

    @Test("Act I classifies document boundaries without applying relationship laws yet")
    @MainActor
    func simplestBoundaryClassification() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let first = try unitAndBlock(containing: 37, in: edition)
        let sameDocument = try unitAndBlock(containing: 40, in: edition)
        let nextDocument = try unitAndBlock(containing: 41, in: edition)

        let start = DocumentPaginationLaw.evidence(for: 37, in: first.block)
        let body = DocumentPaginationLaw.evidence(for: 40, in: sameDocument.block)
        let next = DocumentPaginationLaw.evidence(for: 41, in: nextDocument.block)

        #expect(DocumentPaginationLaw.disposition(between: start, and: body) == .allowed)
        #expect(DocumentPaginationLaw.disposition(between: body, and: next) == .preferred)
    }

    @Test("Act I defines law only and does not alter PaginationEngine behavior")
    func paginationEngineDoesNotConsumeActILawYet() throws {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let packageRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let engineURL = packageRoot.appendingPathComponent(
            "Sources/JJWWPagination/PaginationEngine.swift"
        )
        let source = try String(contentsOf: engineURL, encoding: .utf8)

        #expect(!source.contains("DocumentPaginationLaw"))
        #expect(!source.contains("DocumentBreakDisposition"))
    }

    @MainActor
    private func unitAndBlock(
        containing line: Int,
        in edition: Edition
    ) throws -> (unit: ReadingUnit, block: DocumentBlock) {
        let unit = try #require(
            edition.orderedReadingUnits.first { $0.canonicalAnchor.contains(line: line) }
        )
        let block = try #require(
            unit.blocks.first { $0.canonicalAnchor.contains(line: line) }
        )
        return (unit, block)
    }
}
