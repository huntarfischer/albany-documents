import Foundation
import Testing
import JJWWReaderCore
@testable import JJWWPagination

@Suite("JJWW Stage 8 Final Seal")
struct Stage8FinalSealTests {
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

    @Test("Stage 8 freezes the accepted canonical, semantic, typography, and pagination contracts")
    @MainActor
    func finalStage8ContractIsSealed() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let inventory = DocumentPaginationLaw.inventory(in: edition)
        let configuration = PaginationConfiguration()
        let pagination = try PaginationEngine().paginate(
            edition: edition,
            configuration: configuration
        )

        #expect(edition.canonicalLineSequenceSHA256 == "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e")
        #expect(edition.orderedReadingUnits.count == 75)
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).count == 82)
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).flatMap(\.lines).count == 2_069)
        #expect(edition.orderedReadingUnits.allSatisfy { $0.kind != .cover })

        #expect(inventory.uniqueStructuralSpanCount == 468)
        #expect(inventory.uniqueSourceOccurrenceCount == 82)
        #expect(inventory.uniqueSourceContextCount == 44)

        #expect(DocumentPaginationLaw.version == "stage8c-act1-document-law-v0.1")
        #expect(configuration.typographyProfileVersion == "typography-stage8b-parity-v0.1")
        #expect(configuration.pageCompositionProfileVersion == "page-composition-stage8b-parity-v0.1")
        #expect(DocumentBreakDisposition.allCases == [.preferred, .allowed, .avoid, .keep])

        #expect(!pagination.pages.isEmpty)
        #expect(pagination.pages.allSatisfy { !$0.fragments.isEmpty })
        for (index, page) in pagination.pages.enumerated() {
            #expect(page.pageIndex == index)
            #expect(page.segmentTextRange.length > 0)
        }

        for unit in edition.orderedReadingUnits {
            #expect(
                pagination.reconstructedCanonicalText(for: unit.id) == unit.canonicalText,
                "Stage 8 must reconstruct \(unit.id) exactly"
            )
        }
    }
}
