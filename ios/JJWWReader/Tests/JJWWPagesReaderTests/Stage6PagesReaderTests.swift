import Foundation
import Testing
import JJWWReaderCore
import JJWWScrollReader
import JJWWPagination
@testable import JJWWPagesReader

@Suite("JJWW Reader Stage 6 Pages + Synchronization")
struct Stage6PagesReaderTests {
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

    @Test("Scroll to Pages resolves the exact semantic location to its containing leaf")
    @MainActor
    func scrollToPagesContainingLeaf() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let session = ScrollReaderSession(
            edition: edition,
            persistence: MemoryReaderLocationPersistence()
        )
        let location = ReaderLocation(
            readingUnitID: "confession-of-jesse-james-strang",
            blockID: "confession.primary",
            canonicalLine: 201,
            utf16OffsetInLine: 7
        )
        session.move(to: location, requestScrollNavigation: false)
        let coordinator = try ReaderLocationCoordinator(edition: edition, scrollSession: session)

        coordinator.enterPages()

        #expect(session.displayMode == .pages)
        #expect(coordinator.currentPage?.contains(location) == true)
        #expect(session.location == location)
    }

    @Test("Switching to Pages and back without turning a leaf does not drift")
    @MainActor
    func repeatedNoTurnRoundTripDoesNotDrift() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let session = ScrollReaderSession(
            edition: edition,
            persistence: MemoryReaderLocationPersistence()
        )
        let origin = ReaderLocation(
            readingUnitID: "trial-of-jesse-james-strang",
            blockID: "trial.jesse",
            canonicalLine: 450,
            utf16OffsetInLine: 4
        )
        session.move(to: origin, requestScrollNavigation: false)
        let coordinator = try ReaderLocationCoordinator(edition: edition, scrollSession: session)

        for _ in 0..<12 {
            coordinator.enterPages()
            coordinator.enterScroll()
            #expect(session.location == origin)
            #expect(session.displayMode == .scroll)
        }
    }

    @Test("A completed leaf turn updates the shared semantic location by exactly one PageSlice")
    @MainActor
    func turnMovesOneLeaf() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let session = ScrollReaderSession(
            edition: edition,
            persistence: MemoryReaderLocationPersistence()
        )
        let origin = ReaderLocation(
            readingUnitID: "confession-of-jesse-james-strang",
            blockID: "confession.primary",
            canonicalLine: 201,
            utf16OffsetInLine: 2
        )
        session.move(to: origin, requestScrollNavigation: false)
        let coordinator = try ReaderLocationCoordinator(edition: edition, scrollSession: session)
        coordinator.enterPages()
        let before = coordinator.currentPageIndex

        coordinator.turnForward()

        #expect(coordinator.currentPageIndex == before + 1)
        #expect(session.location == coordinator.currentPage?.startLocation)
        coordinator.enterScroll()
        #expect(session.location == coordinator.pagination.pages[before + 1].startLocation)
    }

    @Test("Page boundaries cannot turn beyond the first or last leaf")
    @MainActor
    func boundariesClamp() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let session = ScrollReaderSession(
            edition: edition,
            persistence: MemoryReaderLocationPersistence()
        )
        let coordinator = try ReaderLocationCoordinator(edition: edition, scrollSession: session)

        coordinator.showPage(index: 0)
        coordinator.turnBackward()
        #expect(coordinator.currentPageIndex == 0)
        #expect(!coordinator.canTurnBackward)

        let last = coordinator.pagination.pages.count - 1
        coordinator.showPage(index: last)
        coordinator.turnForward()
        #expect(coordinator.currentPageIndex == last)
        #expect(!coordinator.canTurnForward)
    }

    @Test("Accessibility repagination preserves the nearest semantic anchor")
    @MainActor
    func repaginationPreservesSemanticAnchor() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let session = ScrollReaderSession(
            edition: edition,
            persistence: MemoryReaderLocationPersistence()
        )
        let origin = ReaderLocation(
            readingUnitID: "trial-of-jesse-james-strang",
            blockID: "trial.jesse",
            canonicalLine: 541,
            utf16OffsetInLine: 3
        )
        session.move(to: origin, requestScrollNavigation: false)
        let coordinator = try ReaderLocationCoordinator(edition: edition, scrollSession: session)
        coordinator.enterPages()

        try coordinator.repaginate(textScale: .accessibility)

        #expect(coordinator.currentPage?.contains(origin) == true)
        #expect(session.location == origin)
        #expect(session.textScale == .accessibility)
    }

    @Test("Reduce Motion swaps curl for a non-curl horizontal transition")
    func reduceMotionPolicy() {
        #expect(PageTurnPolicy.transition(reduceMotion: false) == .pageCurl)
        #expect(PageTurnPolicy.transition(reduceMotion: true) == .horizontalScroll)
    }

    @Test("Stage 6 pagination still reconstructs every source exactly")
    @MainActor
    func canonicalContentStillExact() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let session = ScrollReaderSession(
            edition: edition,
            persistence: MemoryReaderLocationPersistence()
        )
        let coordinator = try ReaderLocationCoordinator(edition: edition, scrollSession: session)

        for unit in edition.orderedReadingUnits where unit.kind != .cover {
            #expect(coordinator.pagination.reconstructedCanonicalText(for: unit.id) == unit.canonicalText)
        }
    }
}
