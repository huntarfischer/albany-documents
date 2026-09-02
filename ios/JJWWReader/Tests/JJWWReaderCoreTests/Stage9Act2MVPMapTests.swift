import Foundation
import Testing
@testable import JJWWReaderCore

@Suite("JJWW Stage 9 Act II MVP Map")
struct Stage9Act2MVPMapTests {
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

    @Test("MVP visual families remap real ReadingUnits without touching canonical ownership")
    func mappedFamiliesStayCanonical() throws {
        let map = try Stage8EditionMap.load(canonicalURL: canonicalURL)
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)

        #expect(edition.version == "stage9-act2-mvp-v1")
        #expect(edition.orderedReadingUnits.count == 75)
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).count == 82)
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).flatMap(\.lines).count == 2_069)
        #expect(
            edition.canonicalLineSequenceSHA256 ==
            "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e"
        )

        let expectations: [(id: String, typography: String, material: String, variant: String?)] = [
            ("unit-l1-cnt-0033", "confessionPamphlet1827", "confessionPamphlet1827", "confessionPamphlet1827"),
            ("unit-l1-cnt-0045", "publishedAccountPamphlet", "confessionPamphlet1827", "publishedAccountPamphlet"),
            ("unit-l1-cnt-0048", "officialDocument", "officialDocument", "officialDocument"),
            ("unit-l1-cnt-0053", "newspaper1967", "newspaper1967", "newspaper1967"),
            ("unit-l1-cnt-0054", "displayArtifact", "farewell1827", "displayDocument"),
            ("unit-l1-cnt-0058", "historicalBook", "historicalBook", "historicalBookExcerpt"),
            ("unit-l1-cnt-0066", "correspondence", "correspondence", "correspondence"),
            ("unit-l1-cnt-0073", "newspaper1905", "newspaper1905", "newspaper1905"),
            ("unit-l1-cnt-0076", "referenceBackMatter", "referenceBackMatter", "referenceBackMatter")
        ]

        for expected in expectations {
            let unit = try #require(edition.readingUnit(id: expected.id))
            let entry = try #require(map.entry(id: expected.id))
            #expect(unit.typographyProfile.id == expected.typography)
            #expect(unit.materialProfile.id == expected.material)
            #expect(unit.presentationFamily == entry.presentationFamily)
            #expect(unit.presentationVariant == entry.presentationVariant)
            #expect(unit.presentationVariant == expected.variant)
        }

        #expect(edition.orderedReadingUnits.allSatisfy { $0.presentationFamily != nil })
        #expect(try #require(edition.readingUnit(id: "unit-l1-cnt-0001")).materialProfile.id == "jjwwEditorial")
        #expect(try #require(edition.readingUnit(id: "unit-l1-cnt-0013")).materialProfile.id == "jjwwEditorial")
    }
}
