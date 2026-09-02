import Foundation
import JJWWReaderCore
import JJWWTypography

public enum PageCompositionKind: String, Codable, CaseIterable, Sendable {
    case standard
    case sectionOpening
    case titlePlate
    case newspaperOpening
    case trialOpening
    case verseOpening
    case continuation
}

public struct PageCompositionProfile: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var displayName: String
    public var openingMargins: PageMargins
    public var continuationMargins: PageMargins
    public var bodyLeadingMultiplier: Double
    public var paragraphIndent: Double
    public var paragraphGap: Double
    public var headerScale: Double
    public var headerTrackingDelta: Double
    public var headerLineSpacingMultiplier: Double
    public var headerTopSpace: Double
    public var headerBottomSpace: Double
    public var runningHeaderPointSize: Double
    public var ruleThickness: Double
    public var ruleLengthFraction: Double
    public var ruleGap: Double
    public var printWear: PrintWearProfile

    public init(
        id: String,
        displayName: String,
        openingMargins: PageMargins,
        continuationMargins: PageMargins,
        bodyLeadingMultiplier: Double,
        paragraphIndent: Double,
        paragraphGap: Double,
        headerScale: Double,
        headerTrackingDelta: Double,
        headerLineSpacingMultiplier: Double,
        headerTopSpace: Double,
        headerBottomSpace: Double,
        runningHeaderPointSize: Double,
        ruleThickness: Double,
        ruleLengthFraction: Double,
        ruleGap: Double,
        printWear: PrintWearProfile
    ) {
        self.id = id
        self.displayName = displayName
        self.openingMargins = openingMargins
        self.continuationMargins = continuationMargins
        self.bodyLeadingMultiplier = bodyLeadingMultiplier
        self.paragraphIndent = paragraphIndent
        self.paragraphGap = paragraphGap
        self.headerScale = headerScale
        self.headerTrackingDelta = headerTrackingDelta
        self.headerLineSpacingMultiplier = headerLineSpacingMultiplier
        self.headerTopSpace = headerTopSpace
        self.headerBottomSpace = headerBottomSpace
        self.runningHeaderPointSize = runningHeaderPointSize
        self.ruleThickness = ruleThickness
        self.ruleLengthFraction = ruleLengthFraction
        self.ruleGap = ruleGap
        self.printWear = printWear
    }

    public init(shared: ReaderCompositionProfile) {
        self.init(
            id: shared.id,
            displayName: shared.displayName,
            openingMargins: PageMargins(
                top: shared.openingInsets.top,
                leading: shared.openingInsets.leading,
                bottom: shared.openingInsets.bottom,
                trailing: shared.openingInsets.trailing
            ),
            continuationMargins: PageMargins(
                top: shared.continuationInsets.top,
                leading: shared.continuationInsets.leading,
                bottom: shared.continuationInsets.bottom,
                trailing: shared.continuationInsets.trailing
            ),
            bodyLeadingMultiplier: shared.bodyLeadingMultiplier,
            paragraphIndent: shared.paragraphIndent,
            paragraphGap: shared.paragraphGap,
            headerScale: shared.headerScale,
            headerTrackingDelta: shared.headerTrackingDelta,
            headerLineSpacingMultiplier: shared.headerLineSpacingMultiplier,
            headerTopSpace: shared.headerTopSpace,
            headerBottomSpace: shared.headerBottomSpace,
            runningHeaderPointSize: shared.runningHeaderPointSize,
            ruleThickness: shared.ruleThickness,
            ruleLengthFraction: shared.ruleLengthFraction,
            ruleGap: shared.ruleGap,
            printWear: shared.printWear
        )
    }

    public func margins(for kind: PageCompositionKind) -> PageMargins {
        kind == .continuation ? continuationMargins : openingMargins
    }
}

/// Pagination adapts the shared source-composition catalog into PageMargins.
/// All visual values still originate in JJWWTypography.ReaderCompositionCatalog,
/// which is also consumed directly by Scroll.
public enum PageCompositionCatalog {
    public static let argus = PageCompositionProfile(shared: ReaderCompositionCatalog.argus)
    public static let dailyAdvertiser = PageCompositionProfile(shared: ReaderCompositionCatalog.dailyAdvertiser)
    public static let confession = PageCompositionProfile(shared: ReaderCompositionCatalog.confession)
    public static let trial = PageCompositionProfile(shared: ReaderCompositionCatalog.trial)
    public static let farewell = PageCompositionProfile(shared: ReaderCompositionCatalog.farewell)

    public static let all: [PageCompositionProfile] = [
        argus,
        dailyAdvertiser,
        confession,
        trial,
        farewell
    ]

    public static func profile(id: String) -> PageCompositionProfile? {
        if let existing = all.first(where: { $0.id == id }) {
            return existing
        }
        guard let shared = ReaderCompositionCatalog.profile(id: id) else {
            return nil
        }
        return PageCompositionProfile(shared: shared)
    }

    public static func profile(for unit: ReadingUnit) -> PageCompositionProfile {
        PageCompositionProfile(shared: ReaderCompositionCatalog.profile(for: unit))
    }

    public static func kind(for unit: ReadingUnit, opening: Bool) -> PageCompositionKind {
        guard opening else { return .continuation }
        switch unit.sourcePresentation?.sourceKind {
        case .periodical: return .newspaperOpening
        case .trialPamphlet: return .trialOpening
        case .literaryArtifact: return .verseOpening
        default: return .sectionOpening
        }
    }
}

public enum PageCompositionProfileCodec {
    public static func encode(_ profile: PageCompositionProfile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(profile)
    }

    public static func decode(_ data: Data) throws -> PageCompositionProfile {
        try JSONDecoder().decode(PageCompositionProfile.self, from: data)
    }

    public static func encodeCatalog(_ profiles: [PageCompositionProfile] = PageCompositionCatalog.all) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(profiles)
    }
}
