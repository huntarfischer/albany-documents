import Foundation
import Testing
import JJWWReaderCore
import JJWWMaterials
import JJWWScrollReader
@testable import JJWWBookShell

@Suite("JJWW Stage 8G Production Host Integration")
struct Stage8GProductionHostTests {
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

    @Test("The live production shell can initialize the complete audited Edition")
    @MainActor
    func fullProductionShellInitializes() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let shell = try makeShell(edition: edition)
        let blocks = shell.edition.orderedReadingUnits.flatMap(\.blocks)
        let lines = blocks.flatMap(\.lines)

        #expect(shell.edition.readingUnits.count == 75)
        #expect(blocks.count == 82)
        #expect(lines.count == 2069)
        #expect(lines.map(\.number) == Array(1...2069))
        #expect(shell.firstReadingLocation?.canonicalLine == 1)
        #expect(shell.coordinator.scrollSession.location.canonicalLine == 1)
        #expect(!shell.coordinator.pagination.pages.isEmpty)
    }

    @Test("The complete Edition enters Pages and returns to the same semantic Scroll location")
    @MainActor
    func fullProductionModeRoundTripDoesNotDrift() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let shell = try makeShell(edition: edition)

        shell.openBook(preferredMode: .scroll)
        let start = shell.coordinator.scrollSession.location

        #expect(shell.phase == .reading)
        #expect(start.canonicalLine == 1)
        #expect(shell.coordinator.scrollSession.displayMode == .scroll)

        shell.setDisplayMode(.pages)
        #expect(shell.coordinator.scrollSession.displayMode == .pages)
        #expect(shell.coordinator.currentPage != nil)

        shell.setDisplayMode(.scroll)
        #expect(shell.coordinator.scrollSession.displayMode == .scroll)
        #expect(shell.coordinator.scrollSession.location == start)
    }

    @Test("Production host milestones span the complete Edition rather than the five-unit Stage 0 rehearsal")
    @MainActor
    func productionProgressModelUsesCompleteEdition() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let shell = try makeShell(edition: edition)

        #expect(shell.progressSpine.milestones.count == 75)
        #expect(shell.progressSpine.milestones.first?.normalizedPosition == 0)
        #expect(shell.progressSpine.milestones.last?.normalizedPosition == 1)
    }

    @MainActor
    private func makeShell(edition: Edition) throws -> BookShellSession {
        try BookShellSession(
            edition: edition,
            materialStore: MaterialProfileStore.bundled(),
            gallery: EditorialGalleryStore.bundled(),
            persistence: MemoryReaderLocationPersistence()
        )
    }
}
