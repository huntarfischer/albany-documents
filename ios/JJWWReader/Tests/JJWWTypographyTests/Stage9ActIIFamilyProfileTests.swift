import Foundation
import XCTest
import JJWWReaderCore
@testable import JJWWTypography

final class Stage9ActIIFamilyProfileTests: XCTestCase {
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

    func testThirteenApprovedTextFamiliesHaveIndependentTypographyIDs() {
        let ids = [
            TypographyCatalog.editorial.id,
            TypographyCatalog.newspaper.id,
            TypographyCatalog.newspaper1905.id,
            TypographyCatalog.newspaper1967.id,
            TypographyCatalog.confession.id,
            TypographyCatalog.publishedAccount.id,
            TypographyCatalog.trial.id,
            TypographyCatalog.officialDocument.id,
            TypographyCatalog.historicalBook.id,
            TypographyCatalog.correspondence.id,
            TypographyCatalog.displayArtifact.id,
            TypographyCatalog.farewell.id,
            TypographyCatalog.referenceBackMatter.id
        ]

        XCTAssertEqual(ids.count, 13)
        XCTAssertEqual(Set(ids).count, 13)
    }

    func testProductionUnitsResolveToTheirOwnFamilyCompositions() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let expectations: [(String, String)] = [
            ("unit-l1-cnt-0001", "composition.jjwwEditorial.v0.1"),
            ("argus-may-8-9-1827", "composition.newspaper1827.v0.1"),
            ("unit-l1-cnt-0073", "composition.newspaper1905.v0.1"),
            ("unit-l1-cnt-0053", "composition.newspaper1967.v0.1"),
            ("confession-of-jesse-james-strang", "composition.confession1827.v0.1"),
            ("unit-l1-cnt-0045", "composition.publishedAccountPamphlet.v0.1"),
            ("trial-of-jesse-james-strang", "composition.trial1827.v0.1"),
            ("unit-l1-cnt-0048", "composition.officialDocument.v0.1"),
            ("unit-l1-cnt-0058", "composition.historicalBook.v0.1"),
            ("unit-l1-cnt-0066", "composition.correspondence.v0.1"),
            ("unit-l1-cnt-0054", "composition.displayArtifact.v0.1"),
            ("farewell-address", "composition.farewell1827.v0.2"),
            ("unit-l1-cnt-0076", "composition.referenceBackMatter.v0.1")
        ]

        for (unitID, compositionID) in expectations {
            let unit = try XCTUnwrap(edition.readingUnit(id: unitID))
            XCTAssertEqual(ReaderCompositionCatalog.bundledProfile(for: unit).id, compositionID)
        }
    }

    func testNewspaper1827TuningReachesArgusDailyAdvertiserAndGenericPaper() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let argus = try XCTUnwrap(edition.readingUnit(id: "argus-may-8-9-1827"))
        let daily = try XCTUnwrap(edition.readingUnit(id: "daily-advertiser-june-18-1827"))
        let generic = try XCTUnwrap(edition.readingUnit(id: "unit-l1-cnt-0005"))

        var tuned = ReaderCompositionCatalog.newspaper1827
        tuned.headerScale = 1.50
        ReaderCompositionTuningRegistry.shared.set(tuned)
        defer { ReaderCompositionTuningRegistry.shared.remove(id: tuned.id) }

        XCTAssertEqual(ReaderCompositionCatalog.profile(for: argus).headerScale, 1.50, accuracy: 0.0001)
        XCTAssertEqual(ReaderCompositionCatalog.profile(for: generic).headerScale, 1.50, accuracy: 0.0001)
        XCTAssertEqual(ReaderCompositionCatalog.profile(for: daily).headerScale, 1.46, accuracy: 0.0001)
        XCTAssertEqual(ReaderCompositionCatalog.profile(for: daily).id, tuned.id)
    }

    func testBorrowedFamiliesAreNowIndependent() {
        XCTAssertNotEqual(TypographyCatalog.historicalBook.id, TypographyCatalog.correspondence.id)
        XCTAssertNotEqual(TypographyCatalog.historicalBook.id, TypographyCatalog.referenceBackMatter.id)
        XCTAssertNotEqual(TypographyCatalog.officialDocument.id, TypographyCatalog.trial.id)
        XCTAssertNotEqual(TypographyCatalog.publishedAccount.id, TypographyCatalog.confession.id)
        XCTAssertNotEqual(TypographyCatalog.displayArtifact.id, TypographyCatalog.farewell.id)
        XCTAssertNotEqual(TypographyCatalog.newspaper1905.id, TypographyCatalog.newspaper.id)
        XCTAssertNotEqual(TypographyCatalog.newspaper1967.id, TypographyCatalog.newspaper.id)
    }
}
