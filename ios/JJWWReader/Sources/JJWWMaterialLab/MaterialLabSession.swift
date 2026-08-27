import Foundation
import Combine
import JJWWMaterials

@MainActor
public final class MaterialLabSession: ObservableObject {
    public let profiles: [MaterialProfileDefinition]

    @Published public private(set) var selectedProfileID: String
    @Published public private(set) var draftProfile: MaterialProfileDefinition
    @Published public var materialState: MaterialState
    @Published public var seed: UInt64
    @Published public var transferText: String
    @Published public private(set) var message: String?

    private let engine = MaterialEngine()

    public init(
        profiles: [MaterialProfileDefinition],
        selectedProfileID: String? = nil,
        state: MaterialState = .full,
        seed: UInt64 = 0x4A4A57574D41544C
    ) {
        precondition(!profiles.isEmpty, "MaterialLabSession requires at least one profile")
        self.profiles = profiles
        let selected = profiles.first(where: { $0.id == selectedProfileID }) ?? profiles[0]
        self.selectedProfileID = selected.id
        self.draftProfile = selected
        self.materialState = state
        self.seed = seed
        self.transferText = ""
        self.message = nil
    }

    public var recipe: MaterialResolvedRecipe {
        engine.resolve(profile: draftProfile, state: materialState, seed: seed)
    }

    public func selectProfile(id: String) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }
        selectedProfileID = profile.id
        draftProfile = profile
        transferText = ""
        message = nil
    }

    public func resetSelectedProfile() {
        guard let profile = profiles.first(where: { $0.id == selectedProfileID }) else { return }
        draftProfile = profile
        transferText = ""
        message = "Reset to bundled Stage 1 values"
    }

    public func updateProfile(_ body: (inout MaterialProfileDefinition) -> Void) {
        var copy = draftProfile
        body(&copy)
        draftProfile = copy
        message = nil
    }

    public func setPaperWarmth(_ value: Double) {
        updateProfile { profile in
            var tuning = profile.effectivePaperTuning
            tuning.warmth = value
            profile.paperTuning = tuning
        }
    }

    public func setPaperBrightness(_ value: Double) {
        updateProfile { profile in
            var tuning = profile.effectivePaperTuning
            tuning.brightness = value
            profile.paperTuning = tuning
        }
    }

    public func setInkDensity(_ value: Double) {
        updateProfile { profile in
            var ink = profile.effectiveInk
            ink.density = value
            profile.ink = ink
        }
    }

    public func setInkBleed(_ value: Double) {
        updateProfile { profile in
            var ink = profile.effectiveInk
            ink.bleed = value
            profile.ink = ink
        }
    }

    @discardableResult
    public func exportProfile() throws -> String {
        var export = draftProfile
        export.version = "0.2"
        let text = try MaterialProfileCodec.export(profile: export)
        transferText = text
        message = "Exported \(export.id) as \(MaterialProfileCodec.currentFormatVersion)"
        return text
    }

    public func importProfile() throws {
        let imported = try MaterialProfileCodec.importProfile(from: transferText)
        draftProfile = imported
        selectedProfileID = imported.id
        message = "Imported \(imported.id)"
    }
}

public enum MaterialLabAvailability {
    #if DEBUG
    public static let isEnabled = true
    #else
    public static let isEnabled = false
    #endif
}
