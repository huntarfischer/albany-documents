import Foundation
import Testing
import JJWWReaderCore
@testable import JJWWScrollReader

@Suite("JJWW Stage 8G Pages-to-Scroll Return Race")
struct Stage8GScrollReturnRaceTests {
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

    @Test("A remount visibility report cannot steal the pending Pages-to-Scroll destination")
    @MainActor
    func remountVisibilityCannotResetReturnTarget() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let session = ScrollReaderSession(
            edition: edition,
            persistence: MemoryReaderLocationPersistence()
        )

        let targetUnit = edition.orderedReadingUnits[15]
        let targetBlock = try #require(targetUnit.blocks.first)
        let targetLine = min(
            targetBlock.canonicalAnchor.endLine,
            targetBlock.canonicalAnchor.startLine + 1
        )
        let target = ReaderLocation(
            readingUnitID: targetUnit.id,
            blockID: targetBlock.id,
            canonicalLine: targetLine,
            utf16OffsetInLine: 0
        )

        session.requestPagesMode()
        session.move(to: target, requestScrollNavigation: true)
        session.requestScrollMode()

        let newlyMountedTopUnit = try #require(edition.orderedReadingUnits.first)
        session.focus(unit: newlyMountedTopUnit)

        #expect(session.location == target)

        session.focus(unit: targetUnit)
        #expect(session.location.readingUnitID == targetUnit.id)
        #expect(session.location.blockID == targetBlock.id)

        let laterUnit = edition.orderedReadingUnits[16]
        session.focus(unit: laterUnit)
        #expect(session.location.readingUnitID == laterUnit.id)
    }
}
