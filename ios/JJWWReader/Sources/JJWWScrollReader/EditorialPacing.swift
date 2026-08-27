import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography

public enum EditorialIntervalStyle: String, Codable, CaseIterable, Sendable {
    case articleOrangeOverlap
    case articlePaperBreath
    case sourcePaperBridge
    case orangeSequenceBreak
    case dramaticVoid
}

public struct EditorialIntervalProfile: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let style: EditorialIntervalStyle
    public let height: Double
    public let orangeBandHeight: Double
    public let overlapDepth: Double
    public let horizontalDrift: Double

    public init(
        id: String,
        style: EditorialIntervalStyle,
        height: Double,
        orangeBandHeight: Double,
        overlapDepth: Double,
        horizontalDrift: Double
    ) {
        self.id = id
        self.style = style
        self.height = height
        self.orangeBandHeight = orangeBandHeight
        self.overlapDepth = overlapDepth
        self.horizontalDrift = horizontalDrift
    }
}

public enum EditorialIntervalCatalog {
    public static let articleOrangeOverlap = EditorialIntervalProfile(
        id: "interval.article.orangeOverlap.v0.1",
        style: .articleOrangeOverlap,
        height: 126,
        orangeBandHeight: 74,
        overlapDepth: 20,
        horizontalDrift: 6
    )

    public static let articlePaperBreath = EditorialIntervalProfile(
        id: "interval.article.paperBreath.v0.1",
        style: .articlePaperBreath,
        height: 104,
        orangeBandHeight: 22,
        overlapDepth: 14,
        horizontalDrift: -5
    )

    public static let sourcePaperBridge = EditorialIntervalProfile(
        id: "interval.source.paperBridge.v0.1",
        style: .sourcePaperBridge,
        height: 142,
        orangeBandHeight: 34,
        overlapDepth: 16,
        horizontalDrift: 4
    )

    public static let orangeSequenceBreak = EditorialIntervalProfile(
        id: "interval.source.orangeSequence.v0.1",
        style: .orangeSequenceBreak,
        height: 174,
        orangeBandHeight: 102,
        overlapDepth: 14,
        horizontalDrift: 0
    )

    public static let dramaticVoid = EditorialIntervalProfile(
        id: "interval.source.dramaticVoid.v0.1",
        style: .dramaticVoid,
        height: 220,
        orangeBandHeight: 36,
        overlapDepth: 10,
        horizontalDrift: 0
    )

    public static func articleBoundary(in unit: ReadingUnit, boundaryIndex: Int) -> EditorialIntervalProfile? {
        guard unit.sourcePresentation?.sourceKind == .periodical,
              boundaryIndex >= 0,
              boundaryIndex < max(0, unit.blocks.count - 1) else { return nil }
        return boundaryIndex.isMultiple(of: 2) ? articleOrangeOverlap : articlePaperBreath
    }

    public static func sourceBoundary(from previous: ReadingUnit, to next: ReadingUnit) -> EditorialIntervalProfile? {
        guard previous.kind != .cover, next.kind != .cover else { return nil }

        if previous.sourcePresentation?.sourceKind == .periodical,
           next.sourcePresentation?.sourceKind == .periodical {
            return sourcePaperBridge
        }
        if next.sourcePresentation?.sourceKind == .confessionPamphlet {
            return orangeSequenceBreak
        }
        if next.sourcePresentation?.sourceKind == .trialPamphlet {
            return sourcePaperBridge
        }
        if next.sourcePresentation?.sourceKind == .literaryArtifact {
            return dramaticVoid
        }
        return sourcePaperBridge
    }
}

public enum FarewellColumnSide: String, Codable, Sendable {
    case leading
    case trailing
}

/// The surviving Farewell broadside is a two-column object. On a phone we preserve
/// that structure serially: its historical left column first, then its historical
/// right column, never two narrow digital columns side by side.
public enum FarewellArtifactLayout {
    public static let unitID = "farewell-address"
    public static let headerRange = 1892...1894
    public static let firstColumnRange = 1895...1926
    public static let secondColumnRange = 1927...1958
    public static let secondColumnStart = 1927

    public static func columnSide(for canonicalLine: Int) -> FarewellColumnSide? {
        if firstColumnRange.contains(canonicalLine) { return .trailing }
        if secondColumnRange.contains(canonicalLine) { return .leading }
        return nil
    }

    public static func isStanzaEnd(_ canonicalLine: Int) -> Bool {
        guard firstColumnRange.contains(canonicalLine) || secondColumnRange.contains(canonicalLine) else {
            return false
        }
        let columnStart = firstColumnRange.contains(canonicalLine)
            ? firstColumnRange.lowerBound
            : secondColumnRange.lowerBound
        return (canonicalLine - columnStart + 1).isMultiple(of: 4)
    }
}

public struct EditorialIntervalView: View {
    public let profile: EditorialIntervalProfile
    public let seed: UInt64

    public init(profile: EditorialIntervalProfile, seed: UInt64) {
        self.profile = profile
        self.seed = seed
    }

    public var body: some View {
        ZStack {
            Color(red: 0.073, green: 0.066, blue: 0.056)

            if profile.orangeBandHeight > 0 {
                EditorialOrangeCloth(seed: seed)
                    .frame(height: clothHeight)
                    .padding(.horizontal, clothSideInset)
                    .offset(
                        x: CGFloat(profile.horizontalDrift),
                        y: clothVerticalOffset
                    )
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: .black.opacity(0.40), radius: 8, y: 5)
            }

            if profile.style == .dramaticVoid {
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color(red: 0.90, green: 0.27, blue: 0.06).opacity(0.78))
                        .frame(width: 54, height: 2)
                    Spacer().frame(height: 42)
                }
            }
        }
        .frame(height: profile.height)
        .accessibilityHidden(true)
    }

    /// The cloth is a physical object underneath the sheets. These dimensions are
    /// deliberately larger than the literal orangeBandHeight so adjacent papers
    /// occlude it and reveal only the authored amount of cloth.
    private var clothHeight: CGFloat {
        switch profile.style {
        case .articleOrangeOverlap:
            return CGFloat(profile.height + profile.overlapDepth * 1.45)
        case .articlePaperBreath:
            return max(62, CGFloat(profile.orangeBandHeight + 42))
        case .sourcePaperBridge:
            return max(92, CGFloat(profile.orangeBandHeight + 58))
        case .orangeSequenceBreak:
            return CGFloat(profile.height + profile.overlapDepth * 1.20)
        case .dramaticVoid:
            return 66
        }
    }

    private var clothSideInset: CGFloat {
        switch profile.style {
        case .articleOrangeOverlap: return 8
        case .articlePaperBreath: return 42
        case .sourcePaperBridge: return 25
        case .orangeSequenceBreak: return 6
        case .dramaticVoid: return 88
        }
    }

    private var clothVerticalOffset: CGFloat {
        switch profile.style {
        case .articleOrangeOverlap: return -2
        case .articlePaperBreath: return 4
        case .sourcePaperBridge: return 2
        case .orangeSequenceBreak: return -1
        case .dramaticVoid: return 10
        }
    }

    private var rotation: Double {
        switch profile.style {
        case .articleOrangeOverlap: return -0.55
        case .articlePaperBreath: return 0.42
        case .sourcePaperBridge: return -0.28
        case .orangeSequenceBreak: return 0.12
        case .dramaticVoid: return 0
        }
    }
}

public struct FarewellColumnOrnament: View {
    public let side: FarewellColumnSide
    public let seed: UInt64

    public init(side: FarewellColumnSide, seed: UInt64) {
        self.side = side
        self.seed = seed
    }

    public var body: some View {
        Canvas { context, size in
            let x = size.width / 2
            var spine = Path()
            spine.move(to: CGPoint(x: x, y: 0))
            spine.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(spine, with: .color(.black.opacity(0.34)), lineWidth: 0.65)

            let spacing: CGFloat = 18
            var y: CGFloat = 9
            var index = 0
            while y < size.height {
                let wobble = CGFloat(((seed &+ UInt64(index * 17)) % 5)) * 0.12
                let center = CGPoint(x: x + wobble - 0.24, y: y)
                var diamond = Path()
                diamond.move(to: CGPoint(x: center.x, y: center.y - 2.3))
                diamond.addLine(to: CGPoint(x: center.x + 2.0, y: center.y))
                diamond.addLine(to: CGPoint(x: center.x, y: center.y + 2.3))
                diamond.addLine(to: CGPoint(x: center.x - 2.0, y: center.y))
                diamond.closeSubpath()
                context.fill(diamond, with: .color(.black.opacity(0.40)))
                y += spacing
                index += 1
            }
        }
        .frame(width: 12)
        .accessibilityHidden(true)
    }
}

private struct EditorialOrangeCloth: View {
    let seed: UInt64

    var body: some View {
        JJWWCoverClothTexture(seed: seed)
            .clipShape(ClothRevealShape(seed: seed))
            .overlay(
                ClothRevealShape(seed: seed)
                    .stroke(Color.black.opacity(0.18), lineWidth: 0.55)
            )
            .accessibilityHidden(true)
    }
}

/// A restrained torn/fabric edge. The paper still owns the foreground silhouette;
/// this only prevents the revealed cloth from reading as a UI rectangle.
private struct ClothRevealShape: Shape {
    let seed: UInt64

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = max(14, Int(rect.width / 24))

        path.move(to: CGPoint(x: 4 + jitter(0, salt: 11, amplitude: 2), y: 5))
        for index in 0...steps {
            let x = rect.width * CGFloat(index) / CGFloat(steps)
            let y = 5 + jitter(index, salt: 29, amplitude: 4.2)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width - 3, y: rect.height - 5))

        for index in stride(from: steps, through: 0, by: -1) {
            let x = rect.width * CGFloat(index) / CGFloat(steps)
            let y = rect.height - 5 + jitter(index, salt: 71, amplitude: 5.4)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.closeSubpath()
        return path
    }

    private func jitter(_ index: Int, salt: UInt64, amplitude: CGFloat) -> CGFloat {
        var value = seed
        value &+= UInt64(index) &* 0x9E3779B97F4A7C15
        value &+= salt &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        value ^= value >> 31
        let unit = Double(value % 10_000) / 9_999.0
        return CGFloat(unit * 2 - 1) * amplitude
    }
}
