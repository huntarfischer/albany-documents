import Foundation
import Testing
@testable import JJWWReaderCore

@Suite("JJWW Stage 9 Act I Reader Identity")
struct Stage9ActIIdentityTests {
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

    @Test("Reader display titles prefer source identity, then canonical headings")
    func displayTitleResolution() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)

        let argus = try #require(edition.readingUnit(id: "argus-may-8-9-1827"))
        #expect(argus.displayTitle == "The Albany Argus & City Gazette")

        let mayTen = try #require(edition.readingUnit(id: "unit-l1-cnt-0005"))
        #expect(mayTen.displayTitle == "Thursday May 10, 1827")

        let opening = try #require(edition.readingUnit(id: "unit-l1-cnt-0001"))
        #expect(opening.displayTitle == "REAL GOOD stories + stuff")

        let delayedTitle = try #require(edition.readingUnit(id: "unit-l1-cnt-0013"))
        #expect(delayedTitle.displayTitle == "ALBANY, NEW YORK")
    }

    @Test("Every production ReadingUnit has human-readable backend identity")
    func everyProductionUnitHasReadableIdentity() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)

        #expect(edition.orderedReadingUnits.count == 75)
        #expect(edition.orderedReadingUnits.allSatisfy { unit in
            unit.displayTitle != unit.id &&
            !unit.displayTitle.lowercased().hasPrefix("[ image:") &&
            !unit.displayTitle.lowercased().hasPrefix("[image:")
        })
    }
}
