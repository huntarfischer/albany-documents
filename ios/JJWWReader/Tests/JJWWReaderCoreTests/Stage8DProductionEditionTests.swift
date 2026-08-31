import Foundation
import Testing
@testable import JJWWReaderCore

@Suite("JJWW Stage 8D Canonical Interior Production Edition")
struct Stage8DProductionEditionTests {
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

    @Test("The production Edition contains no fake canonical cover ReadingUnit")
    func noCanonicalCoverUnit() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)

        #expect(!edition.readingUnits.isEmpty)
        #expect(edition.readingUnits.allSatisfy { $0.kind == .section })
        #expect(edition.readingUnits.allSatisfy { $0.kind != .cover })
    }

    @Test("Opening the production interior begins at canonical line 1")
    func productionInteriorStartsAtLineOne() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let first = try #require(edition.orderedReadingUnits.first)
        let firstBlock = try #require(first.blocks.first)
        let firstLine = try #require(firstBlock.lines.first)

        #expect(first.sequence == 0)
        #expect(first.canonicalAnchor.startLine == 1)
        #expect(firstBlock.canonicalAnchor.startLine == 1)
        #expect(firstBlock.kind == .frontMatter)
        #expect(firstLine.number == 1)
        #expect(firstLine.text == "[ Image: LOGO BLACK.png ]")
    }

    @Test("Every ownership container becomes exactly one production DocumentBlock")
    func oneBlockPerOwner() throws {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let blocks = edition.orderedReadingUnits.flatMap(\.blocks)

        #expect(edition.readingUnits.count == 75)
        #expect(blocks.count == 82)
        #expect(blocks.map(\.canonicalAnchor) == ownership.containers.map(\.canonicalAnchor))
        #expect(blocks.map(\.lines) == ownership.containers.map(\.lines))
        #expect(blocks.map(\.id) == ownership.containers.map { "block-\($0.id.lowercased())" })
        #expect(Set(blocks.map(\.id)).count == 82)
    }

    @Test("Production Edition plainText already reconstructs all canonical v1.1 text")
    func productionEditionReconstructsCanonical() throws {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)

        #expect(edition.canonicalLayer0Version == ownership.canonicalLayer0Version)
        #expect(edition.canonicalLineSequenceSHA256 == ownership.canonicalLineSequenceSHA256)
        #expect(edition.plainText() == ownership.plainText())
        #expect(edition.plainText(includeCover: false) == ownership.plainText())
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).flatMap(\.lines).count == 2069)
    }

    @Test("The five proven presentation precedents survive production Edition construction")
    func provenPresentationPrecedentsSurvive() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)

        let argus = try #require(edition.readingUnit(id: "argus-may-8-9-1827"))
        #expect(argus.typographyProfile == .newspaper1827)
        #expect(argus.materialProfile == .argus1827)
        #expect(argus.blocks.count == 3)
        #expect(argus.blocks.map(\.sourcePassageID) == ["L1-PASS-0001", "L1-PASS-0002", "L1-PASS-0003"])

        let trial = try #require(edition.readingUnit(id: "trial-of-jesse-james-strang"))
        #expect(trial.typographyProfile == .trialRecord1827)
        #expect(trial.materialProfile == .trialRecord1827)
        #expect(trial.blocks.count == 6)
        #expect(trial.blocks.allSatisfy { $0.sourcePassageID == "L1-PASS-0023" })

        let farewell = try #require(edition.readingUnit(id: "farewell-address"))
        #expect(farewell.typographyProfile == .farewell1827)
        #expect(farewell.materialProfile == .farewell1827)
        #expect(farewell.canonicalAnchor.startLine == 1892)
        #expect(farewell.canonicalAnchor.endLine == 1958)
    }

    @Test("The legacy Stage 0 fixture remains available while production Edition is forged beside it")
    func legacyFixtureIsNotDestroyed() throws {
        let stage0 = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let production = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)

        #expect(stage0.readingUnits.contains { $0.kind == .cover })
        #expect(production.readingUnits.allSatisfy { $0.kind == .section })
        #expect(stage0.plainText() != production.plainText())
        #expect(production.orderedReadingUnits.flatMap(\.blocks).flatMap(\.lines).count == 2069)
    }
}
