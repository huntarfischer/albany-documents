import Foundation
import Testing
@testable import JJWWReaderCore

@Suite("JJWW Stage 8C Complete V1 Edition Map")
struct Stage8CEditionMapTests {
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

    @Test("The production map consumes all 82 owners exactly once in canonical order")
    func exactOwnershipConsumption() throws {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let map = try Stage8EditionMap.load(canonicalURL: canonicalURL)

        #expect(map.containerIDs == ownership.containers.map(\.id))
        #expect(map.containerIDs.count == 82)
        #expect(Set(map.containerIDs).count == 82)
        #expect(map.entries.count == 75)
        #expect(map.entries.map(\.sequence) == Array(0..<map.entries.count))
    }

    @Test("Map entry anchors are gapless from canonical line 1 through 2069")
    func entryAnchorsAreGapless() throws {
        let map = try Stage8EditionMap.load(canonicalURL: canonicalURL)
        var nextLine = 1

        for entry in map.entries {
            #expect(entry.canonicalAnchor.canonicalLayer0Version == "1.1")
            #expect(entry.canonicalAnchor.startLine == nextLine)
            #expect(entry.canonicalAnchor.endLine >= entry.canonicalAnchor.startLine)
            nextLine = entry.canonicalAnchor.endLine + 1
        }

        #expect(nextLine == 2070)
        #expect(map.entry(containing: 1)?.canonicalAnchor.startLine == 1)
        #expect(map.entry(containing: 2069)?.canonicalAnchor.endLine == 2069)
    }

    @Test("The five developed prototype treatments survive as production map precedents")
    func provenPrototypeGroupsSurvive() throws {
        let map = try Stage8EditionMap.load(canonicalURL: canonicalURL)

        let argus = try #require(map.entry(id: "argus-may-8-9-1827"))
        #expect(argus.containerIDs == ["L1-CNT-0002", "L1-CNT-0003", "L1-CNT-0004"])
        #expect(argus.canonicalAnchor.startLine == 6)
        #expect(argus.canonicalAnchor.endLine == 23)
        #expect(argus.presentationFamily == .periodical)
        #expect(argus.typographyProfile == .newspaper1827)
        #expect(argus.materialProfile == .argus1827)
        #expect(argus.sourcePresentation?.workID == "L1-WORK-0024")

        let advertiser = try #require(map.entry(id: "daily-advertiser-june-18-1827"))
        #expect(advertiser.containerIDs == ["L1-CNT-0019"])
        #expect(advertiser.canonicalAnchor.startLine == 119)
        #expect(advertiser.canonicalAnchor.endLine == 127)
        #expect(advertiser.presentationFamily == .periodical)
        #expect(advertiser.materialProfile == .dailyAdvertiser1827)

        let confession = try #require(map.entry(id: "confession-of-jesse-james-strang"))
        #expect(confession.containerIDs == ["L1-CNT-0024"])
        #expect(confession.canonicalAnchor.startLine == 173)
        #expect(confession.canonicalAnchor.endLine == 228)
        #expect(confession.presentationFamily == .pamphlet)
        #expect(confession.typographyProfile == .confessionPamphlet1827)

        let trial = try #require(map.entry(id: "trial-of-jesse-james-strang"))
        #expect(trial.containerIDs == [
            "L1-CNT-0025", "L1-CNT-0026", "L1-CNT-0027",
            "L1-CNT-0028", "L1-CNT-0029", "L1-CNT-0030"
        ])
        #expect(trial.canonicalAnchor.startLine == 229)
        #expect(trial.canonicalAnchor.endLine == 584)
        #expect(trial.presentationFamily == .courtLegal)
        #expect(trial.materialProfile == .trialRecord1827)

        let farewell = try #require(map.entry(id: "farewell-address"))
        #expect(farewell.containerIDs == ["L1-CNT-0075"])
        #expect(farewell.canonicalAnchor.startLine == 1892)
        #expect(farewell.canonicalAnchor.endLine == 1958)
        #expect(farewell.presentationFamily == .displayArtifact)
        #expect(farewell.presentationVariant == "farewellBroadside")
        #expect(farewell.typographyProfile == .farewell1827)
        #expect(farewell.materialProfile == .farewell1827)
    }

    @Test("8E classification does not alter the complete 8C map geometry")
    func classificationPreservesMapGeometry() throws {
        let map = try Stage8EditionMap.load(canonicalURL: canonicalURL)

        #expect(map.entries.count == 75)
        #expect(map.containerIDs.count == 82)
        #expect(map.entries.first?.canonicalAnchor.startLine == 1)
        #expect(map.entries.last?.canonicalAnchor.endLine == 2069)
    }

    @Test("The map stores ownership references and expansion rules rather than a second copy of canonical prose")
    func mapDoesNotCopyCanonicalProse() throws {
        let manifestURL = repositoryRoot.appendingPathComponent(
            "ios/JJWWReader/Sources/JJWWReaderCore/Resources/stage8-edition-map-v1.json"
        )
        let manifest = try String(contentsOf: manifestURL, encoding: .utf8)

        #expect(manifest.contains("\"idPrefix\": \"unit-\""))
        #expect(manifest.contains("L1-CNT-0002"))
        #expect(manifest.contains("L1-CNT-0075"))
        #expect(!manifest.contains("Monday June 18, 1827"))
        #expect(!manifest.contains("Farewell, dear friends"))
    }
}
