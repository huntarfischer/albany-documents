import SwiftUI

public enum InkAwakeningEntryContext: String, Codable, Sendable {
    case naturalSectionEntry
    case jumpIntoSection
    case searchResult
}

public enum InkAwakeningBehavior: String, Codable, Sendable {
    case animated
    case shortFade
    case instant
}

public enum InkAwakeningPolicy {
    public static func behavior(
        entryContext: InkAwakeningEntryContext,
        reduceMotion: Bool,
        explicitlyInstant: Bool
    ) -> InkAwakeningBehavior {
        if explicitlyInstant || entryContext != .naturalSectionEntry {
            return .instant
        }
        return reduceMotion ? .shortFade : .animated
    }
}

public enum InkOpacityCurve: String, Codable, CaseIterable, Sendable {
    case linear
    case easeIn
    case easeOut
    case steepMiddle

    func value(at progress: Double) -> Double {
        let p = min(1, max(0, progress))
        switch self {
        case .linear:
            return p
        case .easeIn:
            return p * p
        case .easeOut:
            return 1 - ((1 - p) * (1 - p))
        case .steepMiddle:
            return p * p * (3 - (2 * p))
        }
    }
}

public struct InkAwakeningProfile: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var duration: Double
    public var irregularity: Double
    public var blotScale: Double
    public var revealThreshold: Double
    public var opacityCurve: InkOpacityCurve
    public var feather: Double
    public var traceCount: Int

    public init(
        id: String,
        duration: Double,
        irregularity: Double,
        blotScale: Double,
        revealThreshold: Double,
        opacityCurve: InkOpacityCurve,
        feather: Double,
        traceCount: Int
    ) {
        self.id = id
        self.duration = duration
        self.irregularity = irregularity
        self.blotScale = blotScale
        self.revealThreshold = revealThreshold
        self.opacityCurve = opacityCurve
        self.feather = feather
        self.traceCount = traceCount
    }
}

public enum InkAwakeningCatalog {
    public static let argus = InkAwakeningProfile(
        id: "ink.argus1827",
        duration: 1.05,
        irregularity: 0.80,
        blotScale: 0.85,
        revealThreshold: 0.12,
        opacityCurve: .steepMiddle,
        feather: 0.20,
        traceCount: 74
    )

    public static let dailyAdvertiser = InkAwakeningProfile(
        id: "ink.dailyAdvertiser1827",
        duration: 1.0,
        irregularity: 0.74,
        blotScale: 0.78,
        revealThreshold: 0.10,
        opacityCurve: .steepMiddle,
        feather: 0.18,
        traceCount: 68
    )

    public static let confession = InkAwakeningProfile(
        id: "ink.confession1827",
        duration: 1.18,
        irregularity: 0.66,
        blotScale: 0.72,
        revealThreshold: 0.10,
        opacityCurve: .easeOut,
        feather: 0.16,
        traceCount: 62
    )

    public static let trial = InkAwakeningProfile(
        id: "ink.trial1827",
        duration: 0.92,
        irregularity: 0.58,
        blotScale: 0.68,
        revealThreshold: 0.08,
        opacityCurve: .easeOut,
        feather: 0.12,
        traceCount: 58
    )

    public static let farewell = InkAwakeningProfile(
        id: "ink.farewell1827",
        duration: 1.42,
        irregularity: 0.52,
        blotScale: 0.62,
        revealThreshold: 0.14,
        opacityCurve: .steepMiddle,
        feather: 0.22,
        traceCount: 52
    )

    public static let all: [InkAwakeningProfile] = [argus, dailyAdvertiser, confession, trial, farewell]

    public static func profile(id: String) -> InkAwakeningProfile? {
        all.first { $0.id == id }
    }
}

public struct InkAwakeningText: View {
    private let text: String
    private let token: TypographyToken
    private let profile: InkAwakeningProfile
    private let seed: UInt64
    private let entryContext: InkAwakeningEntryContext
    private let explicitlyInstant: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: Double = 0
    @State private var hasResolved = false

    public init(
        _ text: String,
        token: TypographyToken,
        profile: InkAwakeningProfile,
        seed: UInt64,
        entryContext: InkAwakeningEntryContext = .naturalSectionEntry,
        explicitlyInstant: Bool = false
    ) {
        self.text = text
        self.token = token
        self.profile = profile
        self.seed = seed
        self.entryContext = entryContext
        self.explicitlyInstant = explicitlyInstant
    }

    public var body: some View {
        awakenedText(progress: progress)
            .onAppear(perform: resolveIfNeeded)
            .accessibilityLabel(Text(text))
    }

    private func awakenedText(progress: Double) -> some View {
        TypographicText(text, token: token)
            .mask(
                InkAwakeningMask(
                    progress: progress,
                    profile: profile,
                    seed: seed
                )
            )
            .opacity(progress <= 0.001 ? 0.001 : 1)
    }

    private func resolveIfNeeded() {
        guard !hasResolved else { return }
        hasResolved = true

        switch InkAwakeningPolicy.behavior(
            entryContext: entryContext,
            reduceMotion: reduceMotion,
            explicitlyInstant: explicitlyInstant
        ) {
        case .instant:
            progress = 1
        case .shortFade:
            progress = 0
            withAnimation(.easeOut(duration: 0.16)) {
                progress = 1
            }
        case .animated:
            progress = 0
            withAnimation(.easeInOut(duration: profile.duration)) {
                progress = 1
            }
        }
    }
}

public struct InkAwakeningPreviewText: View {
    private let text: String
    private let token: TypographyToken
    private let profile: InkAwakeningProfile
    private let seed: UInt64
    private let progress: Double

    public init(
        _ text: String,
        token: TypographyToken,
        profile: InkAwakeningProfile,
        seed: UInt64,
        progress: Double
    ) {
        self.text = text
        self.token = token
        self.profile = profile
        self.seed = seed
        self.progress = progress
    }

    public var body: some View {
        TypographicText(text, token: token)
            .mask(InkAwakeningMask(progress: progress, profile: profile, seed: seed))
            .accessibilityLabel(Text(text))
    }
}

private struct InkAwakeningMask: View {
    let progress: Double
    let profile: InkAwakeningProfile
    let seed: UInt64

    var body: some View {
        Canvas { context, size in
            let resolved = profile.opacityCurve.value(at: progress)
            var rng = InkSplitMix64(seed: seed ^ 0x49_4E_4B_4A_4A_57_57)
            let count = max(12, profile.traceCount)

            for index in 0..<count {
                let thresholdBase = Double(index) / Double(max(1, count - 1))
                let jitter = (rng.unit() - 0.5) * profile.irregularity * 0.34
                let threshold = min(0.96, max(0, thresholdBase + jitter + profile.revealThreshold * 0.08))
                guard resolved >= threshold else { continue }

                let localProgress = min(1, max(0, (resolved - threshold) / max(0.06, 1 - threshold)))
                let x = rng.unit() * size.width
                let y = rng.unit() * size.height
                let horizontal = rng.unit() > 0.34
                let baseLength = (0.10 + rng.unit() * 0.36) * (horizontal ? size.width : size.height)
                let thickness = (0.018 + rng.unit() * 0.055) * min(size.width, size.height) * profile.blotScale
                let length = max(2, baseLength * (0.35 + 0.65 * localProgress))
                let rect: CGRect

                if horizontal {
                    rect = CGRect(x: x - length / 2, y: y - thickness / 2, width: length, height: thickness)
                } else {
                    rect = CGRect(x: x - thickness / 2, y: y - length / 2, width: thickness, height: length)
                }

                let path = Path(roundedRect: rect, cornerRadius: max(1, thickness * (0.32 + profile.feather)))
                context.fill(path, with: .color(.white.opacity(0.52 + 0.48 * localProgress)))

                if rng.unit() < profile.irregularity {
                    let satellite = max(1.5, thickness * (0.22 + rng.unit() * 0.34))
                    let satelliteRect = CGRect(
                        x: x + (rng.unit() - 0.5) * thickness * 2.6 - satellite,
                        y: y + (rng.unit() - 0.5) * thickness * 2.6 - satellite,
                        width: satellite * 2,
                        height: satellite * 2
                    )
                    context.fill(Path(ellipseIn: satelliteRect), with: .color(.white.opacity(0.38 + 0.48 * localProgress)))
                }
            }

            if resolved > 0.76 {
                let completion = min(1, (resolved - 0.76) / 0.24)
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(completion)))
            }
        }
        .allowsHitTesting(false)
    }
}

private struct InkSplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
