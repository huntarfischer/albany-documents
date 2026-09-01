import Foundation
import Testing
import JJWWReaderCore
import JJWWScrollReader
import JJWWPagination
@testable import JJWWPagesReader

@Suite("JJWW Reader Stage 8B Native Page Turn Bridge")
struct Stage8BNativePageTurnBridgeTests {
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

    @Test("Completed native curl commits the pending destination even when the visible controller still reports the old leaf")
    func pendingDestinationWinsOverStaleVisibleIndex() {
        var state = NativePageTurnCommitState()

        state.begin(pendingIndex: 7)

        #expect(state.isTransitioning)
        #expect(state.finish(completed: true, visibleIndex: 3) == 7)
        #expect(!state.isTransitioning)
    }

    @Test("Cancelled native curl commits nothing and clears the transition lock")
    func cancelledCurlDoesNotCommit() {
        var state = NativePageTurnCommitState()

        state.begin(pendingIndex: 7)

        #expect(state.finish(completed: false, visibleIndex: 3) == nil)
        #expect(!state.isTransitioning)
    }

    @Test("Successive native curls replace the Pages entry location with the currently visible leaf")
    @MainActor
    func successiveNativeTurnsReturnScrollToCurrentLeaf() throws {
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
        let coordinator = try ReaderLocationCoordinator(
            edition: edition,
            scrollSession: session
        )

        coordinator.enterPages()
        let entryIndex = coordinator.currentPageIndex
        #expect(coordinator.pagination.pages.indices.contains(entryIndex + 2))

        var state = NativePageTurnCommitState()

        state.begin(pendingIndex: entryIndex + 1)
        if let committed = state.finish(
            completed: true,
            visibleIndex: entryIndex
        ) {
            coordinator.showPage(index: committed)
        }

        state.begin(pendingIndex: entryIndex + 2)
        if let committed = state.finish(
            completed: true,
            visibleIndex: entryIndex + 1
        ) {
            coordinator.showPage(index: committed)
        }

        let expected = try #require(coordinator.currentPage?.startLocation)
        #expect(coordinator.currentPageIndex == entryIndex + 2)
        #expect(session.location == expected)

        coordinator.enterScroll()

        #expect(session.displayMode == .scroll)
        #expect(session.location == expected)
    }
}