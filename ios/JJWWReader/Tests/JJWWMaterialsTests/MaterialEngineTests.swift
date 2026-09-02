import Testing
@testable import JJWWMaterials

@Suite("JJWW Material Engine Stage 1")
struct MaterialEngineTests {
    private let expectedProfileIDs = [
        "jjwwEditorial",
        "argus1827",
        "dailyAdvertiser1827",
        "confessionPamphlet1827",
        "trialRecord1827",
        "farewell1827",
        "historicalBook",
        "officialDocument",
        "correspondence",
        "newspaper1905",
        "newspaper1967",
        "referenceBackMatter"
    ]

    @Test("Bundled material catalog includes the prototype and Book 1.0 documentary papers")
    func bundledProfiles() throws {
        let store = try MaterialProfileStore.bundled()
        #expect(store.profiles.map(\.id) == expectedProfileIDs)
        #expect(Set(store.profiles.map(\.version)) == ["0.1"])
        #expect(store.profiles.allSatisfy { $0.scanOverlay.assetName == nil })
    }

    @Test("Same profile and seed resolve identically")
    func deterministicRecipe() throws {
        let store = try MaterialProfileStore.bundled()
        let profile = try #require(store.profile(id: "argus1827"))
        let engine = MaterialEngine()

        let first = engine.resolve(profile: profile, state: .full, seed: 1827)
        let second = engine.resolve(profile: profile, state: .full, seed: 1827)
        #expect(first == second)

        let grainA = DeterministicGrainField.bytes(seed: first.grain.seed, width: 24, height: 24)
        let grainB = DeterministicGrainField.bytes(seed: second.grain.seed, width: 24, height: 24)
        #expect(grainA == grainB)
    }

    @Test("Different seeds produce different related surfaces")
    func seedVariation() throws {
        let store = try MaterialProfileStore.bundled()
        let profile = try #require(store.profile(id: "confessionPamphlet1827"))
        let engine = MaterialEngine()

        let first = engine.resolve(profile: profile, state: .full, seed: 1)
        let second = engine.resolve(profile: profile, state: .full, seed: 2)
        #expect(first != second)
        #expect(first.baseTone == second.baseTone)
        #expect(first.profileID == second.profileID)
        #expect(first.mottles.count == second.mottles.count)
    }

    @Test("Reduced and clean states shed decorative work")
    func materialStatesGetCheaper() throws {
        let store = try MaterialProfileStore.bundled()
        let profile = try #require(store.profile(id: "jjwwEditorial"))
        let engine = MaterialEngine()

        let full = engine.resolve(profile: profile, state: .full, seed: 42)
        let reduced = engine.resolve(profile: profile, state: .reduced, seed: 42)
        let clean = engine.resolve(profile: profile, state: .clean, seed: 42)

        #expect(full.workloadScore > reduced.workloadScore)
        #expect(reduced.workloadScore > clean.workloadScore)
        #expect(clean.decorativeMarkCount == 0)
        #expect(clean.grain.enabled == false)
        #expect(clean.edge.amount == 0)
        #expect(clean.scanOverlay.opacity == 0)
        #expect(clean.baseTone == full.baseTone)
    }

    @Test("Future scan overlay fits the current API")
    func futureScanSlot() throws {
        let store = try MaterialProfileStore.bundled()
        var profile = try #require(store.profile(id: "dailyAdvertiser1827"))
        profile.scanOverlay.assetName = "daily-advertiser-paper-master-01"
        profile.scanOverlay.opacity = 0.72
        profile.scanOverlay.scale = 1.18

        let engine = MaterialEngine()
        let full = engine.resolve(profile: profile, state: .full, seed: 99)
        let reduced = engine.resolve(profile: profile, state: .reduced, seed: 99)
        let clean = engine.resolve(profile: profile, state: .clean, seed: 99)

        #expect(full.scanOverlay.assetName == "daily-advertiser-paper-master-01")
        #expect(full.scanOverlay.opacity == 0.72)
        #expect(reduced.scanOverlay.opacity < full.scanOverlay.opacity)
        #expect(clean.scanOverlay.opacity == 0)
    }

    @Test("Resolved marks are immutable inputs to Canvas, not per-frame randomness")
    func resolvedMarksAreStable() throws {
        let store = try MaterialProfileStore.bundled()
        let profile = try #require(store.profile(id: "farewell1827"))
        let recipe = MaterialEngine().resolve(profile: profile, state: .full, seed: 7)

        let capturedMottles = recipe.mottles
        let capturedFibers = recipe.fibers
        let capturedThreads = recipe.clothThreads

        #expect(recipe.mottles == capturedMottles)
        #expect(recipe.fibers == capturedFibers)
        #expect(recipe.clothThreads == capturedThreads)
    }
}
