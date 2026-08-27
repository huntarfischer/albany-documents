import Foundation
import Testing
import JJWWReaderCore
import JJWWTypography
@testable import JJWWPagination

@Suite("JJWW Reader Stage 5.5 Page Composition")
struct Stage55PageCompositionTests {
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

    @Test("All five prototype sources resolve explicit page composition profiles")
    func profilesResolve() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let units = edition.orderedReadingUnits.filter { $0.kind != .cover }

        #expect(units.count == 5)
        for unit in units {
            let profile = PageCompositionCatalog.profile(for: unit)
            #expect(!profile.id.isEmpty)
            #expect(profile.headerScale >= 1)
            #expect(profile.openingMargins.top > profile.continuationMargins.top)
            #expect(profile.printWear.headerWear >= profile.printWear.bodyWear)
        }
    }

    @Test("Scroll and Pages derive source character from the same composition values")
    func sharedCompositionIdentity() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)

        for unit in edition.orderedReadingUnits where unit.kind != .cover {
            let shared = ReaderCompositionCatalog.profile(for: unit)
            let page = PageCompositionCatalog.profile(for: unit)

            #expect(page.id == shared.id)
            #expect(page.headerScale == shared.headerScale)
            #expect(page.headerTrackingDelta == shared.headerTrackingDelta)
            #expect(page.headerTopSpace == shared.headerTopSpace)
            #expect(page.headerBottomSpace == shared.headerBottomSpace)
            #expect(page.bodyLeadingMultiplier == shared.bodyLeadingMultiplier)
            #expect(page.ruleThickness == shared.ruleThickness)
            #expect(page.ruleLengthFraction == shared.ruleLengthFraction)
            #expect(page.printWear == shared.printWear)
            #expect(page.openingMargins.top == shared.openingInsets.top)
            #expect(page.openingMargins.leading == shared.openingInsets.leading)
            #expect(page.continuationMargins.top == shared.continuationInsets.top)
        }
    }

    @Test("Profile tuning round-trips exactly through versionable JSON")
    func profileRoundTrip() throws {
        var tuned = PageCompositionCatalog.argus
        tuned.headerScale = 1.41
        tuned.headerTopSpace = 31
        tuned.printWear.headerWear = 0.27

        let data = try PageCompositionProfileCodec.encode(tuned)
        let decoded = try PageCompositionProfileCodec.decode(data)
        #expect(decoded == tuned)
    }

    @Test("Opening leaves and continuation leaves carry different composition states")
    @MainActor
    func openingAndContinuationKinds() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        for unit in edition.orderedReadingUnits where unit.kind != .cover {
            let pages = result.pages(representing: unit.id)
            let first = try #require(pages.first)
            #expect(first.compositionKind != .continuation)
            #expect(first.beginsSectionTransition)
            #expect(first.resolvedMargins.top > PageCompositionCatalog.profile(for: unit).continuationMargins.top)
            if pages.count > 1 {
                #expect(pages[1].compositionKind == .continuation)
                #expect(pages[1].resolvedMargins == PageCompositionCatalog.profile(for: unit).continuationMargins)
            }
        }
    }

    @Test("Page composition changes pagination without changing canonical content")
    @MainActor
    func compositionPreservesCanonicalText() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        for unit in edition.orderedReadingUnits where unit.kind != .cover {
            #expect(result.reconstructedCanonicalText(for: unit.id) == unit.canonicalText)
        }
    }

    @Test("Page composition version participates in pagination cache identity")
    func compositionVersionInvalidatesCache() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let a = PaginationConfiguration(pageCompositionProfileVersion: "stage5.5-a")
        let b = PaginationConfiguration(pageCompositionProfileVersion: "stage5.5-b")
        #expect(a.cacheKey(for: edition) != b.cacheKey(for: edition))
    }

    @Test("The lab edits a draft and exports without mutating the catalog default")
    @MainActor
    func labDraftIsolation() throws {
        let source = PageCompositionCatalog.confession
        let session = PageCompositionLabSession(profile: source)
        session.draft.headerScale = 1.52
        let json = try session.exportJSON()
        let decoded = try PageCompositionProfileCodec.decode(Data(json.utf8))

        #expect(decoded.headerScale == 1.52)
        #expect(PageCompositionCatalog.confession.headerScale == source.headerScale)
    }
}
