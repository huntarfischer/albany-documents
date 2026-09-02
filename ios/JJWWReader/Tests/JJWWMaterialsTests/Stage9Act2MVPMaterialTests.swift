import Testing
@testable import JJWWMaterials

@Suite("JJWW Stage 9 Act II MVP Materials")
struct Stage9Act2MVPMaterialTests {
    @Test("Every new Book 1.0 documentary material is bundled and paper-based")
    func documentaryMaterialsLoad() throws {
        let store = try MaterialProfileStore.bundled()
        let ids = [
            "historicalBook",
            "officialDocument",
            "correspondence",
            "newspaper1905",
            "newspaper1967",
            "referenceBackMatter"
        ]

        for id in ids {
            let profile = try #require(store.bundledProfile(id: id))
            #expect(profile.id == id)
            #expect(profile.clothWeave.enabled == false)
            #expect(profile.grain.amount >= 0)
            #expect(profile.edgeVariation.amount >= 0)
        }

        let historical = try #require(store.bundledProfile(id: "historicalBook"))
        let newspaper1967 = try #require(store.bundledProfile(id: "newspaper1967"))
        let reference = try #require(store.bundledProfile(id: "referenceBackMatter"))

        #expect(newspaper1967.grain.amount < historical.grain.amount)
        #expect(reference.edgeVariation.amount < historical.edgeVariation.amount)
    }
}
