import Foundation

public struct MaterialSpot: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let radius: Double
    public let opacity: Double
    public let tone: Double
}

public struct MaterialFiber: Equatable, Sendable {
    public let x1: Double
    public let y1: Double
    public let x2: Double
    public let y2: Double
    public let width: Double
    public let opacity: Double
}

public struct MaterialThread: Equatable, Sendable {
    public enum Axis: String, Sendable {
        case vertical
        case horizontal
    }

    public let axis: Axis
    public let position: Double
    public let width: Double
    public let opacity: Double
    public let tone: Double
}

public struct GrainRecipe: Equatable, Sendable {
    public let enabled: Bool
    public let seed: UInt64
    public let resolution: Int
    public let amount: Double
    public let scale: Double
}

public struct EdgeRecipe: Equatable, Sendable {
    public let amount: Double
    public let width: Double
}

public struct ResolvedScanOverlay: Equatable, Sendable {
    public let assetName: String?
    public let opacity: Double
    public let scale: Double
    public let offsetX: Double
    public let offsetY: Double
}

public struct MaterialResolvedRecipe: Equatable, Sendable {
    public let profileID: String
    public let profileVersion: String
    public let state: MaterialState
    public let seed: UInt64
    public let baseTone: MaterialRGBA
    public let mottles: [MaterialSpot]
    public let grain: GrainRecipe
    public let fibers: [MaterialFiber]
    public let flecks: [MaterialSpot]
    public let foxing: [MaterialSpot]
    public let edge: EdgeRecipe
    public let clothThreads: [MaterialThread]
    public let scanOverlay: ResolvedScanOverlay

    public var decorativeMarkCount: Int {
        mottles.count + fibers.count + flecks.count + foxing.count + clothThreads.count
    }

    public var workloadScore: Int {
        decorativeMarkCount + (grain.enabled ? max(1, grain.resolution * grain.resolution / 512) : 0)
    }
}

public enum MaterialSeed {
    public static func derive(base: UInt64, salt: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325 ^ base
        for byte in salt.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }
}

public struct MaterialEngine: Sendable {
    public init() {}

    public func resolve(
        profile: MaterialProfileDefinition,
        state: MaterialState,
        seed: UInt64
    ) -> MaterialResolvedRecipe {
        let tuning = StateTuning(state: state)
        var rng = SplitMix64(seed: MaterialSeed.derive(base: seed, salt: profile.id))

        let mottleCount = scaledCount(profile.mottling.count, multiplier: tuning.markMultiplier)
        let fiberCount = scaledCount(Int((profile.fibers.density * 120).rounded()), multiplier: tuning.markMultiplier)
        let fleckCount = scaledCount(Int((profile.flecks.density * 90).rounded()), multiplier: tuning.markMultiplier)
        let foxingCount = scaledCount(profile.foxing.count, multiplier: tuning.foxingMultiplier)

        let mottles = (0..<mottleCount).map { _ in
            MaterialSpot(
                x: rng.unit(),
                y: rng.unit(),
                radius: random(in: 0.08...0.28, using: &rng) * profile.mottling.scale,
                opacity: profile.mottling.amount * random(in: 0.35...1.0, using: &rng) * tuning.opacityMultiplier,
                tone: random(in: -1.0...1.0, using: &rng)
            )
        }

        let fibers = (0..<fiberCount).map { _ in
            let x = rng.unit()
            let y = rng.unit()
            let length = random(in: profile.fibers.minLength...profile.fibers.maxLength, using: &rng)
            let angle = random(in: -0.55...0.55, using: &rng)
            return MaterialFiber(
                x1: x,
                y1: y,
                x2: x + cos(angle) * length,
                y2: y + sin(angle) * length,
                width: profile.fibers.width * random(in: 0.65...1.35, using: &rng),
                opacity: profile.fibers.opacity * random(in: 0.45...1.0, using: &rng) * tuning.opacityMultiplier
            )
        }

        let flecks = (0..<fleckCount).map { _ in
            MaterialSpot(
                x: rng.unit(),
                y: rng.unit(),
                radius: random(in: profile.flecks.minRadius...profile.flecks.maxRadius, using: &rng),
                opacity: profile.flecks.opacity * random(in: 0.4...1.0, using: &rng) * tuning.opacityMultiplier,
                tone: random(in: -0.7...0.7, using: &rng)
            )
        }

        let foxing = (0..<foxingCount).map { _ in
            MaterialSpot(
                x: rng.unit(),
                y: rng.unit(),
                radius: random(in: profile.foxing.minRadius...profile.foxing.maxRadius, using: &rng),
                opacity: profile.foxing.amount * random(in: 0.35...1.0, using: &rng) * tuning.opacityMultiplier,
                tone: -1
            )
        }

        var clothThreads: [MaterialThread] = []
        if profile.clothWeave.enabled && tuning.clothMultiplier > 0 {
            let vertical = scaledCount(Int((profile.clothWeave.verticalDensity * 72).rounded()), multiplier: tuning.clothMultiplier)
            let horizontal = scaledCount(Int((profile.clothWeave.horizontalDensity * 72).rounded()), multiplier: tuning.clothMultiplier)

            for index in 0..<vertical {
                let base = Double(index + 1) / Double(vertical + 1)
                clothThreads.append(
                    MaterialThread(
                        axis: .vertical,
                        position: clamped(base + random(in: -0.004...0.004, using: &rng)),
                        width: profile.clothWeave.width * random(in: 0.7...1.25, using: &rng),
                        opacity: profile.clothWeave.opacity * random(in: 0.45...1.0, using: &rng) * tuning.opacityMultiplier,
                        tone: random(in: -1.0...0.6, using: &rng)
                    )
                )
            }

            for index in 0..<horizontal {
                let base = Double(index + 1) / Double(horizontal + 1)
                clothThreads.append(
                    MaterialThread(
                        axis: .horizontal,
                        position: clamped(base + random(in: -0.004...0.004, using: &rng)),
                        width: profile.clothWeave.width * random(in: 0.7...1.25, using: &rng),
                        opacity: profile.clothWeave.opacity * random(in: 0.35...0.85, using: &rng) * tuning.opacityMultiplier,
                        tone: random(in: -0.8...0.8, using: &rng)
                    )
                )
            }
        }

        let grainResolution: Int
        if tuning.grainEnabled {
            grainResolution = state == .reduced ? max(64, profile.grain.resolution / 2) : profile.grain.resolution
        } else {
            grainResolution = 0
        }

        return MaterialResolvedRecipe(
            profileID: profile.id,
            profileVersion: profile.version,
            state: state,
            seed: seed,
            baseTone: profile.baseTone,
            mottles: mottles,
            grain: GrainRecipe(
                enabled: tuning.grainEnabled && profile.grain.amount > 0,
                seed: MaterialSeed.derive(base: seed, salt: "\(profile.id).grain"),
                resolution: grainResolution,
                amount: profile.grain.amount * tuning.opacityMultiplier,
                scale: profile.grain.scale
            ),
            fibers: fibers,
            flecks: flecks,
            foxing: foxing,
            edge: EdgeRecipe(
                amount: profile.edgeVariation.amount * tuning.edgeMultiplier,
                width: profile.edgeVariation.width
            ),
            clothThreads: clothThreads,
            scanOverlay: ResolvedScanOverlay(
                assetName: profile.scanOverlay.assetName,
                opacity: profile.scanOverlay.opacity * tuning.scanMultiplier,
                scale: profile.scanOverlay.scale,
                offsetX: profile.scanOverlay.offsetX,
                offsetY: profile.scanOverlay.offsetY
            )
        )
    }

    private func scaledCount(_ count: Int, multiplier: Double) -> Int {
        guard multiplier > 0, count > 0 else { return 0 }
        return max(1, Int((Double(count) * multiplier).rounded()))
    }

    private func random(in range: ClosedRange<Double>, using rng: inout SplitMix64) -> Double {
        range.lowerBound + (range.upperBound - range.lowerBound) * rng.unit()
    }

    private func clamped(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

private struct StateTuning {
    let markMultiplier: Double
    let foxingMultiplier: Double
    let clothMultiplier: Double
    let opacityMultiplier: Double
    let edgeMultiplier: Double
    let scanMultiplier: Double
    let grainEnabled: Bool

    init(state: MaterialState) {
        switch state {
        case .full:
            markMultiplier = 1
            foxingMultiplier = 1
            clothMultiplier = 1
            opacityMultiplier = 1
            edgeMultiplier = 1
            scanMultiplier = 1
            grainEnabled = true
        case .reduced:
            markMultiplier = 0.34
            foxingMultiplier = 0
            clothMultiplier = 0.38
            opacityMultiplier = 0.42
            edgeMultiplier = 0.35
            scanMultiplier = 0.45
            grainEnabled = true
        case .clean:
            markMultiplier = 0
            foxingMultiplier = 0
            clothMultiplier = 0
            opacityMultiplier = 0
            edgeMultiplier = 0
            scanMultiplier = 0
            grainEnabled = false
        }
    }
}

struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double {
        Double(next() >> 11) / 9_007_199_254_740_992.0
    }
}
