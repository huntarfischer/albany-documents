import SwiftUI

public struct PrintWearProfile: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var headerWear: Double
    public var bodyWear: Double
    public var strokeStarvation: Double
    public var edgeErosion: Double
    public var darkDeposit: Double
    public var seedSalt: UInt64

    // Stage 7.75 moves the hand-tuned 7.5b/c Argus finish into profile data so
    // the Reader Workshop can change it without editing Swift. Optional values
    // keep older exported profile JSON decodable.
    public var wearScale: Double?
    public var starvationCap: Double?
    public var erosionCap: Double?
    public var inkOpacity: Double?
    public var usesMultiplyBlend: Bool?
    public var datePointScale: Double?
    public var sourceHeaderPointScale: Double?
    public var sectionTitlePointScale: Double?
    public var dateTrackingAdjustment: Double?
    public var sourceHeaderTrackingAdjustment: Double?
    public var sectionTitleTrackingAdjustment: Double?
    public var sourceHeaderLineSpacingOverride: Double?

    public init(
        id: String,
        headerWear: Double,
        bodyWear: Double,
        strokeStarvation: Double,
        edgeErosion: Double,
        darkDeposit: Double,
        seedSalt: UInt64,
        wearScale: Double? = nil,
        starvationCap: Double? = nil,
        erosionCap: Double? = nil,
        inkOpacity: Double? = nil,
        usesMultiplyBlend: Bool? = nil,
        datePointScale: Double? = nil,
        sourceHeaderPointScale: Double? = nil,
        sectionTitlePointScale: Double? = nil,
        dateTrackingAdjustment: Double? = nil,
        sourceHeaderTrackingAdjustment: Double? = nil,
        sectionTitleTrackingAdjustment: Double? = nil,
        sourceHeaderLineSpacingOverride: Double? = nil
    ) {
        self.id = id
        self.headerWear = headerWear
        self.bodyWear = bodyWear
        self.strokeStarvation = strokeStarvation
        self.edgeErosion = edgeErosion
        self.darkDeposit = darkDeposit
        self.seedSalt = seedSalt
        self.wearScale = wearScale
        self.starvationCap = starvationCap
        self.erosionCap = erosionCap
        self.inkOpacity = inkOpacity
        self.usesMultiplyBlend = usesMultiplyBlend
        self.datePointScale = datePointScale
        self.sourceHeaderPointScale = sourceHeaderPointScale
        self.sectionTitlePointScale = sectionTitlePointScale
        self.dateTrackingAdjustment = dateTrackingAdjustment
        self.sourceHeaderTrackingAdjustment = sourceHeaderTrackingAdjustment
        self.sectionTitleTrackingAdjustment = sectionTitleTrackingAdjustment
        self.sourceHeaderLineSpacingOverride = sourceHeaderLineSpacingOverride
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
        let canonicalRendered = token.uppercase ? text.uppercased() : text
        let rendered = displayText(for: canonicalRendered)
        let defaultWearScale = isArgusPrint ? 0.48 : 1.0
        let resolvedWearScale = profile.wearScale ?? defaultWearScale
        let intensity = min(0.46, max(0, profile.intensity(for: token.role) * resolvedWearScale))
        let defaultStarvation = isArgusPrint ? min(profile.strokeStarvation, 0.10) : profile.strokeStarvation
        let starvation = min(profile.strokeStarvation, profile.starvationCap ?? defaultStarvation)
        let defaultErosion = isArgusPrint ? min(profile.edgeErosion, 0.08) : profile.edgeErosion
        let erosion = min(profile.edgeErosion, profile.erosionCap ?? defaultErosion)

        ZStack {
            baseText(rendered)
                .mask(
                    PrintWearMask(
                        intensity: intensity,
                        starvation: starvation,
                        erosion: erosion,
                        seed: seed ^ profile.seedSalt
                    )
                )

            if profile.darkDeposit > 0.001, !isArgusPrint {
                baseText(rendered)
                    .opacity(min(0.16, profile.darkDeposit * 0.62))
                    .offset(x: 0.24, y: 0.16)
                    .blendMode(.multiply)
                    .accessibilityHidden(true)
            }
        }
        .blendMode((profile.usesMultiplyBlend ?? isArgusPrint) ? .multiply : .normal)
        .opacity(profile.inkOpacity ?? (isArgusPrint ? 0.94 : 1.0))
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
                pointScale: effectivePointScale,
                trackingDelta: effectiveTrackingDelta,
                lineSpacingMultiplier: lineSpacingMultiplier,
                snapshotLayoutWidth: snapshotLayoutWidth
            )
        } else {
            Text(rendered)
                .font(resolvedFont)
                .tracking(token.tracking + effectiveTrackingDelta)
                .lineSpacing(effectiveLineSpacing)
                .multilineTextAlignment(token.centered ? .center : .leading)
        }
    }

    private var resolvedFont: Font {
        let size = basePointSize(for: token.textStyle) * max(0.60, effectivePointScale)
        if let family = token.fontFamily {
            return .custom(family, size: size).weight(token.weight.swiftUIWeight)
        }
        return .system(
            size: size,
            weight: token.weight.swiftUIWeight,
            design: token.design.swiftUIDesign
        )
    }

    private var effectivePointScale: Double {
        switch token.role {
        case .dateHeading:
            return pointScale * (profile.datePointScale ?? (isArgusPrint ? 0.68 : 1.0))
        case .sourceHeader:
            return pointScale * (profile.sourceHeaderPointScale ?? 1.0)
        case .sectionTitle:
            return pointScale * (profile.sectionTitlePointScale ?? (isArgusPrint ? 0.88 : 1.0))
        default:
            return pointScale
        }
    }

    private var effectiveTrackingDelta: Double {
        switch token.role {
        case .dateHeading:
            return trackingDelta + (profile.dateTrackingAdjustment ?? (isArgusPrint ? -0.25 : 0))
        case .sourceHeader:
            return trackingDelta + (profile.sourceHeaderTrackingAdjustment ?? (isArgusPrint ? -0.20 : 0))
        case .sectionTitle:
            return trackingDelta + (profile.sectionTitleTrackingAdjustment ?? (isArgusPrint ? -trackingDelta : 0))
        default:
            return trackingDelta
        }
    }

    private var effectiveLineSpacing: CGFloat {
        if token.role == .sourceHeader,
           let override = profile.sourceHeaderLineSpacingOverride {
            return override
        }
        if isArgusPrint, token.role == .sourceHeader {
            return -1.5
        }
        return token.lineSpacing * lineSpacingMultiplier
    }

    /// Presentation-only lineation. Canonical text and accessibility stay exact.
    private func displayText(for rendered: String) -> String {
        guard isArgusPrint,
              token.role == .sourceHeader,
              rendered == "THE ALBANY ARGUS & CITY GAZETTE"
        else {
            return rendered
        }
        return "THE ALBANY ARGUS\n& CITY GAZETTE"
    }

    private var isArgusPrint: Bool {
        profile.id.hasPrefix("wear.argus1827")
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
