import Foundation
import Testing
import JJWWReaderCore
import JJWWTypography
@testable import JJWWPagination

@Suite("JJWW Stage 9 Act II MVP Composition")
struct Stage9Act2MVPCompositionTests {
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

    @Test("Representative Stage 9 families share one Scroll and Pages composition identity")
    @MainActor
    func representativeFamiliesReachPages() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)
        let specimens: [(id: String, composition: String)] = [
            ("unit-l1-cnt-0058", "composition.historicalBook.v0.1"),
            ("unit-l1-cnt-0048", "composition.officialDocument.v0.1"),
            ("unit-l1-cnt-0066", "composition.correspondence.v0.1"),
            ("unit-l1-cnt-0073", "composition.newspaper1905.v0.1"),
            ("unit-l1-cnt-0053", "composition.newspaper1967.v0.1"),
            ("unit-l1-cnt-0076", "composition.referenceBackMatter.v0.1")
        ]

        for specimen in specimens {
            let unit = try #require(edition.readingUnit(id: specimen.id))
            let shared = ReaderCompositionCatalog.profile(for: unit)
            let pageProfile = PageCompositionCatalog.profile(for: unit)
            let firstPage = try #require(result.pages(representing: unit.id).first)

            #expect(shared.id == specimen.composition)
            #expect(pageProfile.id == shared.id)
            #expect(firstPage.compositionProfileID == shared.id)
            #expect(PageCompositionCatalog.profile(id: firstPage.compositionProfileID)?.id == shared.id)
            #expect(result.reconstructedCanonicalText(for: unit.id) == unit.canonicalText)
        }
    }
}
