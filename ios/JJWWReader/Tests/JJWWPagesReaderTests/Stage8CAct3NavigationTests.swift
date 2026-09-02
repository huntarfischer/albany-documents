import Foundation
import Testing
import JJWWReaderCore
import JJWWScrollReader
import JJWWPagination
@testable import JJWWPagesReader

@Suite("JJWW Stage 8C Act III Navigation Regression")
struct Stage8CAct3NavigationTests {
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

    @Test("Act III document-aware pagination preserves early, middle, and deep mode round trips")
    @MainActor
    func productionRoundTripsAcrossBook() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let starts = [24, 1_023, 1_892]

        for canonicalLine in starts {
            let location = try #require(location(for: canonicalLine, in: edition))
            let session = ScrollReaderSession(
                edition: edition,
                persistence: MemoryReaderLocationPersistence()
            )
            session.move(to: location, requestScrollNavigation: false)
            let coordinator = try ReaderLocationCoordinator(
                edition: edition,
                scrollSession: session
            )

            coordinator.enterPages()
            #expect(coordinator.currentPage?.contains(location) == true)

            let originPage = coordinator.currentPageIndex
            if coordinator.canTurnForward {
                coordinator.turnForward()
            }
            if coordinator.canTurnForward {
                coordinator.turnForward()
            }
            let expected = try #require(coordinator.currentPage?.startLocation)
            #expect(coordinator.currentPageIndex >= originPage)

            coordinator.enterScroll()
            #expect(session.displayMode == .scroll)
            #expect(session.location == expected)
        }
    }

    @Test("Act III backward and forward turns keep the shared semantic location on the visible leaf")
    @MainActor
    func productionTurnsRemainSynchronized() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let origin = try #require(location(for: 1_174, in: edition))
        let session = ScrollReaderSession(
            edition: edition,
            persistence: MemoryReaderLocationPersistence()
        )
        session.move(to: origin, requestScrollNavigation: false)
        let coordinator = try ReaderLocationCoordinator(
            edition: edition,
            scrollSession: session
        )
        coordinator.enterPages()

        if coordinator.canTurnForward {
            coordinator.turnForward()
            #expect(session.location == coordinator.currentPage?.startLocation)
        }
        if coordinator.canTurnBackward {
            coordinator.turnBackward()
            #expect(session.location == coordinator.currentPage?.startLocation)
        }
    }

    private func location(
        for canonicalLine: Int,
        in edition: Edition
    ) -> ReaderLocation? {
        for unit in edition.orderedReadingUnits {
            for block in unit.blocks where block.canonicalAnchor.contains(line: canonicalLine) {
                guard block.lines.contains(where: { $0.number == canonicalLine }) else { continue }
                return ReaderLocation(
                    readingUnitID: unit.id,
                    blockID: block.id,
                    canonicalLine: canonicalLine,
                    utf16OffsetInLine: 0
                )
            }
        }
        return nil
    }
}
