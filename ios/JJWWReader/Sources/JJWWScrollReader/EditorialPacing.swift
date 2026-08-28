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
        height: 112,
        orangeBandHeight: 74,
        overlapDepth: 24,
        horizontalDrift: 6
    )

    public static let articlePaperBreath = EditorialIntervalProfile(
        id: "interval.article.paperBreath.v0.1",
        style: .articlePaperBreath,
        height: 78,
        orangeBandHeight: 22,
        overlapDepth: 18,
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

/// Stage 7.5a treats an interval as authored exposure of the table below.
/// It deliberately draws no orange object of its own. In a periodical stack the
/// transparent space reveals that stack's continuous cloth background; elsewhere
/// it reveals the Scroll reader's underlying table.
public struct EditorialIntervalView: View {
    public let profile: EditorialIntervalProfile
    public let seed: UInt64

    public init(profile: EditorialIntervalProfile, seed: UInt64) {
        self.profile = profile
        self.seed = seed
    }

    public var body: some View {
        Color.clear
            .frame(height: profile.height)
            .accessibilityHidden(true)
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
