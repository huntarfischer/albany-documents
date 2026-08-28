import SwiftUI

public struct PrintWearProfile: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var headerWear: Double
    public var bodyWear: Double
    public var strokeStarvation: Double
    public var edgeErosion: Double
    public var darkDeposit: Double
    public var seedSalt: UInt64

    public init(
        id: String,
        headerWear: Double,
        bodyWear: Double,
        strokeStarvation: Double,
        edgeErosion: Double,
        darkDeposit: Double,
        seedSalt: UInt64
    ) {
        self.id = id
        self.headerWear = headerWear
        self.bodyWear = bodyWear
        self.strokeStarvation = strokeStarvation
        self.edgeErosion = edgeErosion
        self.darkDeposit = darkDeposit
        self.seedSalt = seedSalt
    }

    public func intensity(for role: TypographyRole) -> Double {
        switch role {
        case .dateHeading, .sourceHeader, .sectionTitle, .editorialCutPaper:
            return headerWear
        default:
            return bodyWear
        }
    }
}

public struct PrintWearText: View {
    private let text: String
    private let token: TypographyToken
    private let profile: PrintWearProfile
    private let seed: UInt64
    private let pointScale: Double
    private let trackingDelta: Double
    private let lineSpacingMultiplier: Double
    private let snapshotLayoutWidth: Double?

    public init(
        _ text: String,
        token: TypographyToken,
        profile: PrintWearProfile,
        seed: UInt64,
        pointScale: Double = 1,
        trackingDelta: Double = 0,
        lineSpacingMultiplier: Double = 1,
        snapshotLayoutWidth: Double? = nil
    ) {
        self.text = text
        self.token = token
        self.profile = profile
        self.seed = seed
        self.pointScale = pointScale
        self.trackingDelta = trackingDelta
        self.lineSpacingMultiplier = lineSpacingMultiplier
        self.snapshotLayoutWidth = snapshotLayoutWidth
    }

    public var body: some View {
        let rendered = token.uppercase ? text.uppercased() : text
        let intensity = min(0.46, max(0, profile.intensity(for: token.role)))

        ZStack {
            baseText(rendered)
                .mask(
                    PrintWearMask(
                        intensity: intensity,
                        starvation: profile.strokeStarvation,
                        erosion: profile.edgeErosion,
                        seed: seed ^ profile.seedSalt
                    )
                )

            if profile.darkDeposit > 0.001 {
                baseText(rendered)
                    .opacity(min(0.16, profile.darkDeposit * 0.62))
                    .offset(x: 0.24, y: 0.16)
                    .blendMode(.multiply)
                    .accessibilityHidden(true)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(text))
    }

    @ViewBuilder
    private func baseText(_ rendered: String) -> some View {
        if token.justified {
            JustifiedTypographicText(
                rendered,
                token: token,
                pointScale: pointScale,
                trackingDelta: trackingDelta,
                lineSpacingMultiplier: lineSpacingMultiplier,
                snapshotLayoutWidth: snapshotLayoutWidth
            )
        } else {
            Text(rendered)
                .font(resolvedFont)
                .tracking(token.tracking + trackingDelta)
                .lineSpacing(token.lineSpacing * lineSpacingMultiplier)
                .multilineTextAlignment(token.centered ? .center : .leading)
        }
    }

    private var resolvedFont: Font {
        let size = basePointSize(for: token.textStyle) * max(0.75, pointScale)
        switch token.design {
        case .baskerville:
            return .custom("Baskerville", size: size).weight(token.weight.swiftUIWeight)
        case .bodoni:
            return .custom("Bodoni 72", size: size).weight(token.weight.swiftUIWeight)
        default:
            return .system(
                size: size,
                weight: token.weight.swiftUIWeight,
                design: token.design.swiftUIDesign
            )
        }
    }

    private func basePointSize(for style: TypographyDynamicTextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        }
    }
}

private struct PrintWearMask: View {
    let intensity: Double
    let starvation: Double
    let erosion: Double
    let seed: UInt64

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            guard intensity > 0.001 else { return }

            var rng = PrintWearSplitMix64(seed: seed ^ 0x50_52_49_4E_54_57_52)
            let area = max(1, size.width * size.height)
            let density = 0.00005 + intensity * 0.00120
            let count = max(1, min(180, Int(area * density)))

            context.blendMode = .destinationOut
            for _ in 0..<count {
                let x = rng.unit() * size.width
                let y = rng.unit() * size.height
                let elongated = rng.unit() < 0.66
                let base = 0.65 + rng.unit() * (2.30 + 3.20 * erosion)
                let width = elongated ? base * (2.0 + 2.5 * starvation) : base
                let height = elongated ? base * (0.34 + 0.58 * erosion) : base
                let rect = CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)
                let alpha = min(0.92, 0.22 + intensity * 1.70 + rng.unit() * 0.20)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct PrintWearSplitMix64 {
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
