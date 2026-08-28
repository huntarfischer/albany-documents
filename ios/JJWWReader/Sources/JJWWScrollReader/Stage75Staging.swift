import Foundation
import JJWWReaderCore

/// Physical sheet staging for Stage 7.5 periodicals. Stage 7.75 promotes the
/// values that were previously embedded in Swift into a tunable profile so the
/// Reader Workshop can adjust the actual production stack.
public struct PeriodicalStagingProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var sheetInsetScale: Double
    public var sheetDriftScale: Double
    public var sheetRotationScale: Double
    public var backingLayerLimit: Int
    public var backingDriftScale: Double
    public var deckleScale: Double
    public var contactShadowOpacity: Double
    public var contactShadowRadius: Double
    public var contactShadowY: Double
    public var ambientShadowOpacity: Double
    public var ambientShadowRadius: Double
    public var ambientShadowY: Double
    public var intervalHeightScale: Double
    public var stackVerticalPadding: Double

    public init(
        id: String,
        sheetInsetScale: Double = 1,
        sheetDriftScale: Double = 1,
        sheetRotationScale: Double = 1,
        backingLayerLimit: Int = 2,
        backingDriftScale: Double = 1,
        deckleScale: Double = 1,
        contactShadowOpacity: Double = 0.23,
        contactShadowRadius: Double = 2.0,
        contactShadowY: Double = 2.2,
        ambientShadowOpacity: Double = 0.33,
        ambientShadowRadius: Double = 9.5,
        ambientShadowY: Double = 6.5,
        intervalHeightScale: Double = 1,
        stackVerticalPadding: Double = 12
    ) {
        self.id = id
        self.sheetInsetScale = sheetInsetScale
        self.sheetDriftScale = sheetDriftScale
        self.sheetRotationScale = sheetRotationScale
        self.backingLayerLimit = backingLayerLimit
        self.backingDriftScale = backingDriftScale
        self.deckleScale = deckleScale
        self.contactShadowOpacity = contactShadowOpacity
        self.contactShadowRadius = contactShadowRadius
        self.contactShadowY = contactShadowY
        self.ambientShadowOpacity = ambientShadowOpacity
        self.ambientShadowRadius = ambientShadowRadius
        self.ambientShadowY = ambientShadowY
        self.intervalHeightScale = intervalHeightScale
        self.stackVerticalPadding = stackVerticalPadding
    }
}

public final class PeriodicalStagingTuningRegistry: @unchecked Sendable {
    public static let shared = PeriodicalStagingTuningRegistry()

    private let lock = NSLock()
    private var overrides: [String: PeriodicalStagingProfile] = [:]

    private init() {}

    public func profile(id: String) -> PeriodicalStagingProfile? {
        lock.lock()
        defer { lock.unlock() }
        return overrides[id]
    }

    public func set(_ profile: PeriodicalStagingProfile) {
        lock.lock()
        overrides[profile.id] = profile
        lock.unlock()
    }

    public func remove(id: String) {
        lock.lock()
        overrides.removeValue(forKey: id)
        lock.unlock()
    }

    public func removeAll() {
        lock.lock()
        overrides.removeAll()
        lock.unlock()
    }
}

public enum PeriodicalStagingCatalog {
    public static func id(for unit: ReadingUnit) -> String {
        "staging.\(unit.materialProfile.id).v0.1"
    }

    public static func bundledProfile(for unit: ReadingUnit) -> PeriodicalStagingProfile {
        PeriodicalStagingProfile(id: id(for: unit))
    }

    public static func profile(for unit: ReadingUnit) -> PeriodicalStagingProfile {
        let base = bundledProfile(for: unit)
        return PeriodicalStagingTuningRegistry.shared.profile(id: base.id) ?? base
    }
}
