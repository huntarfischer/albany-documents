import Foundation
import Testing
import JJWWReaderCore
import JJWWScrollReader
@testable import JJWWPagination

@Suite("JJWW Reader Stage 5 Pagination")
struct Stage5PaginationTests {
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

    @Test("Pagination preserves every canonical character exactly once")
    @MainActor
    func exactCanonicalCoverage() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        for unit in edition.orderedReadingUnits where unit.kind != .cover {
            #expect(result.reconstructedCanonicalText(for: unit.id) == unit.canonicalText)
        }
        #expect(result.pages.allSatisfy { !$0.readingUnitIDs.contains("cover") })
    }

    @Test("Adjacent PageSlices are contiguous inside each TextKit layout segment")
    @MainActor
    func contiguousSegmentRanges() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)
        let grouped = Dictionary(grouping: result.pages, by: \.layoutSegmentID)

        for pages in grouped.values {
            let ordered = pages.sorted { $0.pageIndex < $1.pageIndex }
            for pair in zip(ordered, ordered.dropFirst()) {
                #expect(pair.0.segmentTextRange.upperBound == pair.1.segmentTextRange.location)
            }
        }
    }

    @Test("Re-pagination preserves a semantic ReaderLocation")
    @MainActor
    func semanticLocationSurvivesRepagination() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let location = ReaderLocation(
            readingUnitID: "trial-of-jesse-james-strang",
            blockID: "trial.jesse",
            canonicalLine: 450,
            utf16OffsetInLine: 4
        )
        let engine = PaginationEngine()

        let standard = try engine.paginate(
            edition: edition,
            configuration: PaginationConfiguration(textScale: .standard)
        )
        let accessibility = try engine.paginate(
            edition: edition,
            configuration: PaginationConfiguration(textScale: .accessibility)
        )

        #expect(standard.page(containing: location) != nil)
        #expect(accessibility.page(containing: location) != nil)
        #expect(standard.page(containing: location)?.startLocation != accessibility.page(containing: location)?.startLocation || standard.pages.count != accessibility.pages.count)
    }

    @Test("Large accessibility text on a compact phone still yields valid complete pages")
    @MainActor
    func accessibilityPagination() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let compact = PageGeometry(
            width: 320,
            height: 568,
            margins: PageMargins(top: 34, leading: 24, bottom: 38, trailing: 24)
        )
        let result = try PaginationEngine().paginate(
            edition: edition,
            configuration: PaginationConfiguration(
                geometry: compact,
                textScale: .accessibility,
                marginProfileVersion: "compact-stage5-v0.1"
            )
        )

        #expect(!result.pages.isEmpty)
        for unit in edition.orderedReadingUnits where unit.kind != .cover {
            #expect(result.reconstructedCanonicalText(for: unit.id) == unit.canonicalText)
        }
    }

    @Test("Geometry, type scale, margins, rules, and edition identity participate in the cache key")
    func cacheKeyInvalidation() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let portrait = PaginationConfiguration()
        let landscape = PaginationConfiguration(
            geometry: PageGeometry(
                width: 844,
                height: 390,
                margins: PageMargins(top: 28, leading: 48, bottom: 28, trailing: 48)
            )
        )
        let large = PaginationConfiguration(textScale: .large)

        #expect(portrait.cacheKey(for: edition) != landscape.cacheKey(for: edition))
        #expect(portrait.cacheKey(for: edition) != large.cacheKey(for: edition))
    }

    @Test("Prototype source/material transitions begin on explicit new leaves")
    @MainActor
    func sourceTransitionsBeginLeaves() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)
        let units = edition.orderedReadingUnits.filter { $0.kind != .cover }

        for index in 0..<(units.count - 1) {
            let left = try #require(result.pages(representing: units[index].id).last)
            let right = try #require(result.pages(representing: units[index + 1].id).first)
            #expect(left.pageIndex + 1 == right.pageIndex)
            #expect(right.beginsSectionTransition)
        }
    }

    @Test("Page sides alternate recto and verso without changing content")
    @MainActor
    func rectoVersoAlternation() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        for page in result.pages {
            #expect(page.side == (page.pageIndex.isMultiple(of: 2) ? .recto : .verso))
        }
    }
}
