import Testing
@testable import JJWWBookShell

@Suite("JJWW Reader Stage 7.8 Native Host Finish")
struct Stage78HostFinishTests {
    @Test("Production gallery assets are bundled and shell assets are not reported as unplaced")
    func productionAssetsResolveWithCorrectStatus() throws {
        let gallery = try EditorialGalleryStore.bundled()

        let cover = try #require(gallery.asset(id: "jjww-cover-current"))
        let publisherMark = try #require(gallery.asset(id: "real-good-stories-symbol"))
        let delayedTitle = try #require(gallery.asset(id: "jjww-albany-delayed-title-plate"))

        #expect(cover.isAvailable)
        #expect(publisherMark.isAvailable)
        #expect(delayedTitle.isAvailable)

        #expect(EditorialGalleryView.statusText(cover) == "SHELL")
        #expect(EditorialGalleryView.statusText(publisherMark) == "SHELL")
        #expect(EditorialGalleryView.statusText(delayedTitle) == "UNPLACED")
    }

    @Test("The delayed Albany title remains deliberately without an invented placement")
    func delayedTitleRemainsUnplaced() throws {
        let gallery = try EditorialGalleryStore.bundled()
        let delayedTitle = try #require(gallery.asset(id: "jjww-albany-delayed-title-plate"))

        #expect(delayedTitle.descriptor.placement == nil)
        #expect(delayedTitle.descriptor.role == .delayedTitlePlate)
    }
}
