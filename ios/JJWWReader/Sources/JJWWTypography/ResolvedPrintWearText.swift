import SwiftUI

/// Print wear is now strictly visual. All geometry is supplied by the same
/// ResolvedReaderTypography value that pagination measured.
public struct ResolvedPrintWearText: View {
    private let canonicalText: String
    private let resolved: ResolvedReaderTypography
    private let profile: PrintWearProfile
    private let seed: UInt64
    private let snapshotLayoutWidth: Double?

    public init(
        _ canonicalText: String,
        resolved: ResolvedReaderTypography,
        profile: PrintWearProfile,
        seed: UInt64,
        snapshotLayoutWidth: Double? = nil
    ) {
        self.canonicalText = canonicalText
        self.resolved = resolved
        self.profile = profile
        self.seed = seed
        self.snapshotLayoutWidth = snapshotLayoutWidth
    }

    public var body: some View {
        let argus = profile.id.hasPrefix("wear.argus1827")
        let defaultWearScale = argus ? 0.48 : 1.0
        let resolvedWearScale = profile.wearScale ?? defaultWearScale
        let intensity = min(
            0.46,
            max(0, profile.intensity(for: resolved.token.role) * resolvedWearScale)
        )
        let defaultStarvation = argus
            ? min(profile.strokeStarvation, 0.10)
            : profile.strokeStarvation
        let starvation = min(
            profile.strokeStarvation,
            profile.starvationCap ?? defaultStarvation
        )
        let defaultErosion = argus
            ? min(profile.edgeErosion, 0.08)
            : profile.edgeErosion
        let erosion = min(
            profile.edgeErosion,
            profile.erosionCap ?? defaultErosion
        )

        ZStack {
            resolvedText
                .mask(
                    ResolvedPrintWearMask(
                        intensity: intensity,
                        starvation: starvation,
                        erosion: erosion,
                        seed: seed ^ profile.seedSalt
                    )
                )

            if profile.darkDeposit > 0.001, !argus {
                resolvedText
                    .opacity(min(0.16, profile.darkDeposit * 0.62))
                    .offset(x: 0.24, y: 0.16)
                    .blendMode(.multiply)
                    .accessibilityHidden(true)
            }
        }
        .blendMode((profile.usesMultiplyBlend ?? argus) ? .multiply : .normal)
        .opacity(profile.inkOpacity ?? (argus ? 0.94 : 1.0))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(canonicalText))
    }

    @ViewBuilder
    private var resolvedText: some View {
        if resolved.token.justified {
            ResolvedJustifiedTypographicText(
                resolved.displayText,
                resolved: resolved,
                snapshotLayoutWidth: snapshotLayoutWidth
            )
        } else {
            Text(resolved.displayText)
                .font(resolved.swiftUIFont)
                .tracking(resolved.tracking)
                .lineSpacing(resolved.lineSpacing)
                .multilineTextAlignment(
                    resolved.token.centered ? .center : .leading
                )
        }
    }
}

private struct ResolvedPrintWearMask: View {
    let intensity: Double
    let starvation: Double
    let erosion: Double
    let seed: UInt64

    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.white)
            )
            guard intensity > 0.001 else { return }

            var rng = ResolvedPrintWearSplitMix64(
                seed: seed ^ 0x50_52_49_4E_54_57_52
            )
            let area = max(1, size.width * size.height)
            let density = 0.00005 + intensity * 0.00120
            let count = max(1, min(180, Int(area * density)))

            context.blendMode = .destinationOut
            for _ in 0..<count {
                let x = rng.unit() * size.width
                let y = rng.unit() * size.height
                let elongated = rng.unit() < 0.66
                let base = 0.65 + rng.unit() * (2.30 + 3.20 * erosion)
                let width = elongated
                    ? base * (2.0 + 2.5 * starvation)
                    : base
                let height = elongated
                    ? base * (0.34 + 0.58 * erosion)
                    : base
                let rect = CGRect(
                    x: x - width / 2,
                    y: y - height / 2,
                    width: width,
                    height: height
                )
                let alpha = min(
                    0.92,
                    0.22 + intensity * 1.70 + rng.unit() * 0.20
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ResolvedPrintWearSplitMix64 {
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
