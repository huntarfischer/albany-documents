import Foundation
import Testing
@testable import JJWWReaderCore

@Suite("JJWW Stage 8E Presentation Family Classification")
struct Stage8EPresentationClassificationTests {
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

    @Test("All 75 production ReadingUnits have a presentation family")
    func allEntriesAreClassified() throws {
        let map = try Stage8EditionMap.load(canonicalURL: canonicalURL)

        #expect(map.entries.count == 75)
        #expect(map.unclassifiedEntries.isEmpty)
        #expect(map.entries.allSatisfy(\.isClassified))
    }

    @Test("The eight production families cover the complete Edition with stable counts")
    func familyCountsAreStable() throws {
        let map = try Stage8EditionMap.load(canonicalURL: canonicalURL)
        let counts = Dictionary(grouping: map.entries, by: \.presentationFamily).mapValues(\.count)

        #expect(counts[.editorialInterior] == 4)
        #expect(counts[.periodical] == 28)
        #expect(counts[.pamphlet] == 5)
        #expect(counts[.courtLegal] == 10)
        #expect(counts[.bookExcerpt] == 13)
        #expect(counts[.standaloneDocument] == 5)
        #expect(counts[.displayArtifact] == 3)
        #expect(counts[.referenceBackMatter] == 7)
        #expect(counts[.unclassified] == nil)
        #expect(counts.values.reduce(0, +) == 75)
    }

    @Test("Classification follows Layer 1 source evidence without inventing a source for unattributed matter")
    func representativeLayer1EvidenceIsRespected() throws {
        let map = try Stage8EditionMap.load(canonicalURL: canonicalURL)
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)

        try expectFamily(.periodical, containerID: "L1-CNT-0005", map: map, ownership: ownership)
        try expectFamily(.bookExcerpt, containerID: "L1-CNT-0023", map: map, ownership: ownership)
        try expectFamily(.courtLegal, containerID: "L1-CNT-0032", map: map, ownership: ownership)
        try expectFamily(.standaloneDocument, containerID: "L1-CNT-0041", map: map, ownership: ownership)
        try expectFamily(.pamphlet, containerID: "L1-CNT-0052", map: map, ownership: ownership)
        try expectFamily(.displayArtifact, containerID: "L1-CNT-0054", map: map, ownership: ownership)
        try expectFamily(.standaloneDocument, containerID: "L1-CNT-0061", map: map, ownership: ownership)
        try expectFamily(.editorialInterior, containerID: "L1-CNT-0063", map: map, ownership: ownership)
        try expectFamily(.editorialInterior, containerID: "L1-CNT-0066", map: map, ownership: ownership)
        try expectFamily(.referenceBackMatter, containerID: "L1-CNT-0079", map: map, ownership: ownership)
    }

    @Test("8E reuses the already-proven typography and material profile vocabulary")
    func noNewProfileIDsAreIntroduced() throws {
        let map = try Stage8EditionMap.load(canonicalURL: canonicalURL)
        let typographyIDs = Set(map.entries.map(\.typographyProfile.id))
        let materialIDs = Set(map.entries.map(\.materialProfile.id))

        #expect(typographyIDs.isSubset(of: [
            "jjwwEditorial", "newspaper1827", "confessionPamphlet1827",
            "trialRecord1827", "farewell1827"
        ]))
        #expect(materialIDs.isSubset(of: [
            "jjwwEditorial", "argus1827", "dailyAdvertiser1827",
            "confessionPamphlet1827", "trialRecord1827", "farewell1827"
        ]))
    }

    @Test("8E changes taxonomy only: ownership and canonical text remain exact")
    func classificationDoesNotChangeCanonicalMatter() throws {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)

        #expect(edition.readingUnits.count == 75)
        #expect(edition.readingUnits.flatMap(\.blocks).count == 82)
        #expect(edition.plainText().split(separator: "\n", omittingEmptySubsequences: false).count == 2069)
        #expect(edition.plainText() == ownership.containers.flatMap(\.lines).map(\.text).joined(separator: "\n"))
    }

    private func expectFamily(
        _ expected: Stage8PresentationFamily,
        containerID: String,
        map: Stage8EditionMapBook,
        ownership: Stage8CanonicalOwnershipBook
    ) throws {
        let container = try #require(ownership.container(id: containerID))
        let entry = try #require(map.entry(containing: container.canonicalAnchor.startLine))
        #expect(entry.presentationFamily == expected)
    }
}
