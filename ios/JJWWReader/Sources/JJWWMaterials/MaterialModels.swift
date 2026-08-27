import Foundation

public enum MaterialState: String, Codable, CaseIterable, Sendable {
    case full
    case reduced
    case clean
}

public struct MaterialRGBA: Codable, Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public struct MottlingProfile: Codable, Equatable, Sendable {
    public var amount: Double
    public var scale: Double
    public var count: Int
}

public struct GrainProfile: Codable, Equatable, Sendable {
    public var amount: Double
    public var scale: Double
    public var resolution: Int
}

public struct FiberProfile: Codable, Equatable, Sendable {
    public var density: Double
    public var minLength: Double
    public var maxLength: Double
    public var opacity: Double
    public var width: Double
}

public struct FleckProfile: Codable, Equatable, Sendable {
    public var density: Double
    public var minRadius: Double
    public var maxRadius: Double
    public var opacity: Double
}

public struct FoxingProfile: Codable, Equatable, Sendable {
    public var amount: Double
    public var minRadius: Double
    public var maxRadius: Double
    public var count: Int
}

public struct EdgeVariationProfile: Codable, Equatable, Sendable {
    public var amount: Double
    public var width: Double
}

public struct ClothWeaveProfile: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var verticalDensity: Double
    public var horizontalDensity: Double
    public var opacity: Double
    public var width: Double
}

public struct ScanOverlayProfile: Codable, Equatable, Sendable {
    public var assetName: String?
    public var opacity: Double
    public var scale: Double
    public var offsetX: Double
    public var offsetY: Double

    public init(
        assetName: String? = nil,
        opacity: Double = 0,
        scale: Double = 1,
        offsetX: Double = 0,
        offsetY: Double = 0
    ) {
        self.assetName = assetName
        self.opacity = opacity
        self.scale = scale
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
}

public struct MaterialProfileDefinition: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var version: String
    public var displayName: String
    public var baseTone: MaterialRGBA
    public var mottling: MottlingProfile
    public var grain: GrainProfile
    public var fibers: FiberProfile
    public var flecks: FleckProfile
    public var foxing: FoxingProfile
    public var edgeVariation: EdgeVariationProfile
    public var clothWeave: ClothWeaveProfile
    public var scanOverlay: ScanOverlayProfile

    public init(
        id: String,
        version: String,
        displayName: String,
        baseTone: MaterialRGBA,
        mottling: MottlingProfile,
        grain: GrainProfile,
        fibers: FiberProfile,
        flecks: FleckProfile,
        foxing: FoxingProfile,
        edgeVariation: EdgeVariationProfile,
        clothWeave: ClothWeaveProfile,
        scanOverlay: ScanOverlayProfile = .init()
    ) {
        self.id = id
        self.version = version
        self.displayName = displayName
        self.baseTone = baseTone
        self.mottling = mottling
        self.grain = grain
        self.fibers = fibers
        self.flecks = flecks
        self.foxing = foxing
        self.edgeVariation = edgeVariation
        self.clothWeave = clothWeave
        self.scanOverlay = scanOverlay
    }
}

public struct MaterialProfileStore: Sendable {
    public let profiles: [MaterialProfileDefinition]

    public init(profiles: [MaterialProfileDefinition]) {
        self.profiles = profiles
    }

    public func profile(id: String) -> MaterialProfileDefinition? {
        profiles.first { $0.id == id }
    }

    public static func bundled() throws -> MaterialProfileStore {
        guard let url = Bundle.module.url(
            forResource: "material-profiles-v0.1",
            withExtension: "json"
        ) else {
            throw MaterialProfileStoreError.bundledProfilesMissing
        }

        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder().decode(MaterialProfilesPayload.self, from: data)
        return MaterialProfileStore(profiles: payload.profiles)
    }
}

public enum MaterialProfileStoreError: Error, Equatable {
    case bundledProfilesMissing
}

private struct MaterialProfilesPayload: Codable {
    let formatVersion: String
    let profiles: [MaterialProfileDefinition]
}
