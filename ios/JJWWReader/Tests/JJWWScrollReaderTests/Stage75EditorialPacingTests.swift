import Foundation
import Testing
import JJWWReaderCore
import JJWWTypography
@testable import JJWWScrollReader

@Suite("JJWW Reader Stage 7.5 Editorial Pacing")
struct Stage75EditorialPacingTests {
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

    @Test("Argus article boundaries alternate authored interval treatments")
    func argusArticleIntervals() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let argus = try #require(edition.readingUnit(id: "argus-may-8-9-1827"))
        #expect(argus.blocks.count == 3)

        let first = try #require(EditorialIntervalCatalog.articleBoundary(in: argus, boundaryIndex: 0))
        let second = try #require(EditorialIntervalCatalog.articleBoundary(in: argus, boundaryIndex: 1))

        #expect(first.style == .articleOrangeOverlap)
        #expect(second.style == .articlePaperBreath)
        #expect(first.height > 90)
        #expect(first.orangeBandHeight > second.orangeBandHeight)
    }

    @Test("Major source changes receive larger sequence punctuation")
    func sourceIntervals() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let daily = try #require(edition.readingUnit(id: "daily-advertiser-june-18-1827"))
        let confession = try #require(edition.readingUnit(id: "confession-of-jesse-james-strang"))
        let trial = try #require(edition.readingUnit(id: "trial-of-jesse-james-strang"))
        let farewell = try #require(edition.readingUnit(id: FarewellArtifactLayout.unitID))

        #expect(EditorialIntervalCatalog.sourceBoundary(from: daily, to: confession)?.style == .orangeSequenceBreak)
        #expect(EditorialIntervalCatalog.sourceBoundary(from: confession, to: trial)?.style == .sourcePaperBridge)
        #expect(EditorialIntervalCatalog.sourceBoundary(from: trial, to: farewell)?.style == .dramaticVoid)
    }

    @Test("Farewell broadside columns are serialized without changing canonical order")
    func farewellColumnModel() {
        #expect(FarewellArtifactLayout.headerRange == 1892...1894)
        #expect(FarewellArtifactLayout.firstColumnRange == 1895...1926)
        #expect(FarewellArtifactLayout.secondColumnRange == 1927...1958)
        #expect(FarewellArtifactLayout.columnSide(for: 1895) == .trailing)
        #expect(FarewellArtifactLayout.columnSide(for: 1927) == .leading)
        #expect(FarewellArtifactLayout.columnSide(for: 1892) == nil)
        #expect(FarewellArtifactLayout.isStanzaEnd(1898))
        #expect(FarewellArtifactLayout.isStanzaEnd(1926))
        #expect(FarewellArtifactLayout.isStanzaEnd(1930))
        #expect(FarewellArtifactLayout.isStanzaEnd(1958))
        #expect(!FarewellArtifactLayout.isStanzaEnd(1897))
    }

    @Test("Farewell typography is one readable column, not centered verse")
    func farewellTypography() {
        let profile = TypographyCatalog.farewell
        #expect(profile.token(.sectionTitle).textStyle.rawValue == "largeTitle")
        #expect(profile.token(.sectionTitle).uppercase)
        #expect(profile.token(.verse).paragraphAlignment == .leading)
        #expect(profile.token(.verse).lineSpacing < 6)
    }
}
