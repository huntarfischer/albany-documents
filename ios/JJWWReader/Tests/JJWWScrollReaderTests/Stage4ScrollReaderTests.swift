import Foundation
import Testing
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography
@testable import JJWWScrollReader

@Suite("JJWW Reader Stage 4 Scroll Reader")
struct Stage4ScrollReaderTests {
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

    @Test("The scroll reader consumes the authored Stage 0 order without reordering")
    func authoredOrderAndExactText() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let ordered = edition.orderedReadingUnits

        #expect(ordered.map(\.sequence) == Array(0...5))
        #expect(ordered.flatMap(\.blocks).flatMap(\.lines).count == 511)

        let reconstructed = ordered
            .flatMap(\.blocks)
            .flatMap(\.lines)
            .map(\.text)
            .joined(separator: "\n")
        #expect(reconstructed == edition.plainText())
    }

    @Test("Every configured reading unit resolves a material and typography profile")
    func profilesResolve() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let materials = try MaterialProfileStore.bundled()

        for unit in edition.orderedReadingUnits {
            #expect(materials.profile(id: unit.materialProfile.id) != nil)
            #expect(TypographyCatalog.profile(id: unit.typographyProfile.id) != nil)
        }
    }

    @Test("Section opening roles are derived from canonical lines and feed Ink Awakening")
    func openingRoles() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)

        for unit in edition.orderedReadingUnits where unit.kind == .section {
            let presentations = unit.blocks.flatMap {
                ReaderLineRoleResolver.presentations(for: $0, in: unit)
            }
            #expect(presentations.contains(where: \.usesInkAwakening))
        }

        let farewell = try #require(edition.readingUnit(id: "farewell-address"))
        let farewellRoles = farewell.blocks.flatMap {
            ReaderLineRoleResolver.presentations(for: $0, in: farewell)
        }
        #expect(farewellRoles.contains { $0.role == .verse })

        let confession = try #require(edition.readingUnit(id: "confession-of-jesse-james-strang"))
        let confessionRoles = confession.blocks.flatMap {
            ReaderLineRoleResolver.presentations(for: $0, in: confession)
        }
        #expect(confessionRoles.contains { $0.role == .firstPersonBody })
    }

    @Test("The dense Jesse trial remains one lazy reader unit with exact canonical coverage")
    func trialCoverage() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let trial = try #require(edition.readingUnit(id: "trial-of-jesse-james-strang"))
        let lines = trial.blocks.flatMap(\.lines)

        #expect(lines.count == 356)
        #expect(lines.first?.number == 229)
        #expect(lines.last?.number == 584)
        #expect(lines.map(\.number) == Array(229...584))
    }

    @Test("Material and text controls do not move the stable reader anchor")
    @MainActor
    func controlsPreserveLocation() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let persistence = MemoryReaderLocationPersistence()
        let session = ScrollReaderSession(
            edition: edition,
            persistence: persistence
        )
        let confession = try #require(edition.readingUnit(id: "confession-of-jesse-james-strang"))
        session.focus(unit: confession, canonicalLine: 200)
        let before = session.location

        session.changingMaterial(to: .clean)
        session.changingTextScale(to: .accessibility)

        #expect(session.location == before)
        #expect(session.materialSetting == .clean)
        #expect(session.textScale == .accessibility)
    }

    @Test("Reader location persists as semantic IDs and canonical line, never screen offset")
    @MainActor
    func stableLocationPersistence() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let persistence = MemoryReaderLocationPersistence()
        let first = ScrollReaderSession(edition: edition, persistence: persistence)
        let trial = try #require(edition.readingUnit(id: "trial-of-jesse-james-strang"))
        first.focus(unit: trial, canonicalLine: 450)

        let restored = ScrollReaderSession(edition: edition, persistence: persistence)
        #expect(restored.location.readingUnitID == trial.id)
        #expect(restored.location.canonicalLine == 450)
        #expect(restored.location.blockID == "trial.jesse")
    }

    @Test("Pages remains a disabled Stage 4 placeholder")
    @MainActor
    func pagesPlaceholder() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let session = ScrollReaderSession(
            edition: edition,
            persistence: MemoryReaderLocationPersistence()
        )

        #expect(session.displayMode == .scroll)
        session.requestPagesMode()
        #expect(session.displayMode == .scroll)
    }
}
