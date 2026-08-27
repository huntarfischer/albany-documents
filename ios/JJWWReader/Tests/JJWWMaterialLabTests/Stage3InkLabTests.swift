import XCTest
@testable import JJWWMaterialLab
@testable import JJWWTypography

#if DEBUG
@MainActor
final class Stage3InkLabTests: XCTestCase {
    func testInkLabRoundTripPreservesDraft() throws {
        let session = InkLabSession(profiles: InkAwakeningCatalog.all, seed: 1827)
        session.selectProfile(id: InkAwakeningCatalog.farewell.id)
        session.update {
            $0.duration = 1.77
            $0.irregularity = 0.41
            $0.feather = 0.29
        }
        let expected = session.draftProfile
        _ = try session.exportProfile()
        session.update { $0.duration = 0.2 }
        try session.importProfile()
        XCTAssertEqual(session.draftProfile, expected)
    }

    func testInkLabTuningDoesNotMutateBundledCatalog() {
        let original = InkAwakeningCatalog.argus
        let session = InkLabSession(profiles: InkAwakeningCatalog.all)
        session.update { $0.duration = 2.2 }
        XCTAssertEqual(InkAwakeningCatalog.argus, original)
        XCTAssertNotEqual(session.draftProfile.duration, original.duration)
    }
}
#endif
