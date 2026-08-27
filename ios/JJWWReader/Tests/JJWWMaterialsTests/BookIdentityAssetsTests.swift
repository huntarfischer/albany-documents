import XCTest
@testable import JJWWMaterials

final class BookIdentityAssetsTests: XCTestCase {
    func testBundledBookIdentityArtworkIsPresent() {
        XCTAssertNotNil(JJWWBookIdentityAssets.titleArtURL)
        XCTAssertNotNil(JJWWBookIdentityAssets.coupleCutoutURL)
    }
}
