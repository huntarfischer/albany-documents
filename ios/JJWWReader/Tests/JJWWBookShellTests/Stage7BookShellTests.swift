import Foundation
import Testing
import JJWWReaderCore
import JJWWMaterials
import JJWWScrollReader
@testable import JJWWBookShell

@Suite("JJWW Reader Stage 7 Cover + Binding + Gallery")
struct Stage7BookShellTests {
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

    @Test("Cover threshold opens onto the first real manuscript reading location")
    @MainActor
    func coverOpensIntoManuscript() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let shell = try makeShell(edition: edition, persistence: MemoryReaderLocationPersistence())

        #expect(shell.phase == .cover)
        #expect(shell.coordinator.scrollSession.location.canonicalLine == 1)

        shell.openBook(preferredMode: .scroll)

        #expect(shell.phase == .reading)
        #expect(shell.coordinator.scrollSession.location.readingUnitID == "argus-may-8-9-1827")
        #expect(shell.coordinator.scrollSession.location.canonicalLine == 6)
        #expect(shell.coordinator.scrollSession.displayMode == .scroll)
    }

    @Test("Continue Reading preserves a persisted semantic location")
    @MainActor
    func continueReadingPreservesLocation() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let persistence = MemoryReaderLocationPersistence()
        let saved = ReaderLocation(
            readingUnitID: "confession-of-jesse-james-strang",
            blockID: "confession.primary",
            canonicalLine: 200,
            utf16OffsetInLine: 5
        )
        persistence.save(saved, editionID: edition.id)

        let shell = try makeShell(edition: edition, persistence: persistence)
        #expect(shell.hasResumeLocation)
        shell.continueReading()

        #expect(shell.phase == .reading)
        #expect(shell.coordinator.scrollSession.location == saved)
    }

    @Test("Progress spine marks source transitions rather than paragraphs")
    func progressSpineUsesReadingUnits() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let model = ProgressSpineModel(edition: edition)

        #expect(model.milestones.count == 5)
        #expect(model.milestones.map(\.id) == [
            "argus-may-8-9-1827",
            "daily-advertiser-june-18-1827",
            "confession-of-jesse-james-strang",
            "trial-of-jesse-james-strang",
            "farewell-address"
        ])

        let positions = model.milestones.map(\.normalizedPosition)
        #expect(zip(positions, positions.dropFirst()).allSatisfy { $0 <= $1 })
    }

    @Test("Gallery reserves the supplied cover, publisher mark, and delayed Albany title plate")
    func gallerySeedsKnownEditorialAssets() throws {
        let gallery = try EditorialGalleryStore.bundled()

        #expect(gallery.manifestVersion == "0.1")
        #expect(gallery.asset(id: "jjww-cover-current")?.descriptor.role == .cover)
        #expect(gallery.asset(id: "real-good-stories-symbol")?.descriptor.role == .publisherMark)
        #expect(gallery.asset(id: "jjww-albany-delayed-title-plate")?.descriptor.role == .delayedTitlePlate)
    }

    @Test("Gallery recursively discovers research images in nested folders")
    func galleryResearchDiscoveryIsRecursive() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("jjww-gallery-\(UUID().uuidString)", isDirectory: true)
        let nested = root
            .appendingPathComponent("Research", isDirectory: true)
            .appendingPathComponent("Maps", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try Data([0]).write(to: nested.appendingPathComponent("albany-1827.JPG"))
        try Data([0]).write(to: nested.appendingPathComponent("notes.txt"))

        let discovered = EditorialGalleryStore.discoverImageFiles(at: root)

        #expect(discovered.map(\.lastPathComponent) == ["albany-1827.JPG"])
    }

    @Test("Delayed Albany title plate has no invented canonical placement")
    func delayedTitlePlacementIsNotGuessed() throws {
        let gallery = try EditorialGalleryStore.bundled()
        let titlePlate = try #require(gallery.asset(id: "jjww-albany-delayed-title-plate"))
        #expect(titlePlate.descriptor.placement == nil)
    }

    @Test("Explicit gallery placement resolves by canonical line and edge")
    func placementResolverIsExact() {
        let descriptor = EditorialAssetDescriptor(
            id: "test-image",
            filename: "test.png",
            role: .illustration,
            title: "Test",
            altText: "Test image",
            insertionStyle: .captioned,
            placement: EditorialAssetPlacement(canonicalLine: 119, edge: .after)
        )
        let store = EditorialGalleryStore(
            manifestVersion: "0.1",
            assets: [ResolvedEditorialAsset(descriptor: descriptor, resourceURL: nil)]
        )

        #expect(store.assets(atCanonicalLine: 119, edge: .after).map(\.id) == ["test-image"])
        #expect(store.assets(atCanonicalLine: 119, edge: .before).isEmpty)
        #expect(store.assets(atCanonicalLine: 120, edge: .after).isEmpty)
    }

    @MainActor
    private func makeShell(
        edition: Edition,
        persistence: ReaderLocationPersistence
    ) throws -> BookShellSession {
        try BookShellSession(
            edition: edition,
            materialStore: MaterialProfileStore.bundled(),
            gallery: EditorialGalleryStore.bundled(),
            persistence: persistence
        )
    }
}
