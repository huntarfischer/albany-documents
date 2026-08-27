import Testing
import JJWWMaterials
@testable import JJWWMaterialLab

@Suite("JJWW Material Lab Stage 2")
@MainActor
struct MaterialLabTests {
    @Test("Export and import round-trip preserves the tuned profile")
    func exportImportRoundTrip() throws {
        let profiles = try MaterialProfileStore.bundled().profiles
        let session = MaterialLabSession(profiles: profiles, selectedProfileID: "argus1827")
        session.setPaperWarmth(0.11)
        session.setPaperBrightness(-0.03)
        session.setInkDensity(0.81)
        session.setInkBleed(0.22)
        session.updateProfile {
            $0.mottling.amount = 0.137
            $0.fibers.density = 0.333
            $0.scanOverlay.scale = 1.27
        }

        let text = try session.exportProfile()
        let imported = try MaterialProfileCodec.importProfile(from: text)

        var expected = session.draftProfile
        expected.version = "0.2"
        #expect(imported == expected)
        #expect(text.contains("0.2-material-profile"))
    }

    @Test("Editing a draft never mutates bundled source profile values")
    func draftIsValueSemantic() throws {
        let profiles = try MaterialProfileStore.bundled().profiles
        let original = try #require(profiles.first(where: { $0.id == "farewell1827" }))
        let session = MaterialLabSession(profiles: profiles, selectedProfileID: original.id)

        session.updateProfile {
            $0.grain.amount = 0.399
            $0.foxing.count = 19
        }

        #expect(session.draftProfile != original)
        #expect(session.profiles.first(where: { $0.id == original.id }) == original)
    }

    @Test("Same tuned profile and seed still resolve deterministically")
    func tunedDeterminism() throws {
        let profiles = try MaterialProfileStore.bundled().profiles
        let session = MaterialLabSession(profiles: profiles, selectedProfileID: "jjwwEditorial", seed: 1827)
        session.setPaperWarmth(0.07)
        session.updateProfile { $0.clothWeave.verticalDensity = 1.12 }

        let first = session.recipe
        let second = session.recipe
        #expect(first == second)
        #expect(first.baseTone == second.baseTone)
        #expect(first.clothThreads == second.clothThreads)
    }

    @Test("Paper and ink tuning are explicit profile data")
    func tuningFieldsArePersisted() throws {
        let profiles = try MaterialProfileStore.bundled().profiles
        let session = MaterialLabSession(profiles: profiles, selectedProfileID: "dailyAdvertiser1827")
        session.setPaperWarmth(-0.08)
        session.setPaperBrightness(0.04)
        session.setInkDensity(0.76)
        session.setInkBleed(0.31)

        let text = try session.exportProfile()
        let imported = try MaterialProfileCodec.importProfile(from: text)
        #expect(imported.effectivePaperTuning.warmth == -0.08)
        #expect(imported.effectivePaperTuning.brightness == 0.04)
        #expect(imported.effectiveInk.density == 0.76)
        #expect(imported.effectiveInk.bleed == 0.31)
    }

    @Test("All six profiles are selectable without changing the profile set")
    func allProfilesSelectable() throws {
        let profiles = try MaterialProfileStore.bundled().profiles
        let session = MaterialLabSession(profiles: profiles)
        let ids = profiles.map(\.id)

        for id in ids {
            session.selectProfile(id: id)
            #expect(session.selectedProfileID == id)
            #expect(session.draftProfile.id == id)
        }
        #expect(session.profiles.map(\.id) == ids)
    }

    @Test("Material Lab is enabled only in debug compilation")
    func debugAvailability() {
        #if DEBUG
        #expect(MaterialLabAvailability.isEnabled)
        #else
        #expect(!MaterialLabAvailability.isEnabled)
        #endif
    }
}
