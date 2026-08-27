import Foundation
import JJWWReaderCore

/// Presentation geometry and print-condition values shared by Scroll and Pages.
///
/// The two reading modes may lay text out differently, but they must not invent
/// different source identities. Header hierarchy, spacing rhythm, and print wear
/// originate here so a later shell cannot accidentally regress one mode.
public struct ReaderCompositionInsets: Codable, Equatable, Hashable, Sendable {
    public var top: Double
    public var leading: Double
    public var bottom: Double
    public var trailing: Double

    public init(top: Double, leading: Double, bottom: Double, trailing: Double) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

public struct ReaderCompositionProfile: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var displayName: String
    public var openingInsets: ReaderCompositionInsets
    public var continuationInsets: ReaderCompositionInsets
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
        openingInsets: ReaderCompositionInsets,
        continuationInsets: ReaderCompositionInsets,
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
        self.openingInsets = openingInsets
        self.continuationInsets = continuationInsets
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
}

public enum ReaderCompositionCatalog {
    public static let argus = ReaderCompositionProfile(
        id: "composition.argus1827.v0.1",
        displayName: "Argus 1827",
        openingInsets: ReaderCompositionInsets(top: 64, leading: 28, bottom: 50, trailing: 28),
        continuationInsets: ReaderCompositionInsets(top: 44, leading: 28, bottom: 48, trailing: 28),
        bodyLeadingMultiplier: 1.10,
        paragraphIndent: 12,
        paragraphGap: 1.5,
        headerScale: 1.28,
        headerTrackingDelta: 0.45,
        headerLineSpacingMultiplier: 1.08,
        headerTopSpace: 12,
        headerBottomSpace: 24,
        runningHeaderPointSize: 9.5,
        ruleThickness: 0.8,
        ruleLengthFraction: 0.88,
        ruleGap: 10,
        printWear: PrintWearProfile(
            id: "wear.argus1827.v0.1",
            headerWear: 0.20,
            bodyWear: 0.045,
            strokeStarvation: 0.22,
            edgeErosion: 0.18,
            darkDeposit: 0.10,
            seedSalt: 811
        )
    )

    public static let dailyAdvertiser = ReaderCompositionProfile(
        id: "composition.dailyAdvertiser1827.v0.1",
        displayName: "Daily Advertiser 1827",
        openingInsets: ReaderCompositionInsets(top: 68, leading: 30, bottom: 52, trailing: 30),
        continuationInsets: ReaderCompositionInsets(top: 46, leading: 30, bottom: 48, trailing: 30),
        bodyLeadingMultiplier: 1.09,
        paragraphIndent: 12,
        paragraphGap: 1.5,
        headerScale: 1.24,
        headerTrackingDelta: 0.38,
        headerLineSpacingMultiplier: 1.06,
        headerTopSpace: 14,
        headerBottomSpace: 22,
        runningHeaderPointSize: 9.5,
        ruleThickness: 0.75,
        ruleLengthFraction: 0.86,
        ruleGap: 10,
        printWear: PrintWearProfile(
            id: "wear.dailyAdvertiser1827.v0.1",
            headerWear: 0.18,
            bodyWear: 0.040,
            strokeStarvation: 0.20,
            edgeErosion: 0.16,
            darkDeposit: 0.09,
            seedSalt: 817
        )
    )

    public static let confession = ReaderCompositionProfile(
        id: "composition.confession1827.v0.1",
        displayName: "Confession Pamphlet 1827",
        openingInsets: ReaderCompositionInsets(top: 82, leading: 38, bottom: 58, trailing: 38),
        continuationInsets: ReaderCompositionInsets(top: 50, leading: 38, bottom: 54, trailing: 38),
        bodyLeadingMultiplier: 1.14,
        paragraphIndent: 14,
        paragraphGap: 2,
        headerScale: 1.30,
        headerTrackingDelta: 0.34,
        headerLineSpacingMultiplier: 1.10,
        headerTopSpace: 22,
        headerBottomSpace: 30,
        runningHeaderPointSize: 9,
        ruleThickness: 0.65,
        ruleLengthFraction: 0.60,
        ruleGap: 13,
        printWear: PrintWearProfile(
            id: "wear.confession1827.v0.1",
            headerWear: 0.16,
            bodyWear: 0.032,
            strokeStarvation: 0.16,
            edgeErosion: 0.14,
            darkDeposit: 0.08,
            seedSalt: 823
        )
    )

    public static let trial = ReaderCompositionProfile(
        id: "composition.trial1827.v0.1",
        displayName: "Trial Record 1827",
        openingInsets: ReaderCompositionInsets(top: 70, leading: 30, bottom: 50, trailing: 30),
        continuationInsets: ReaderCompositionInsets(top: 42, leading: 30, bottom: 46, trailing: 30),
        bodyLeadingMultiplier: 1.05,
        paragraphIndent: 10,
        paragraphGap: 1,
        headerScale: 1.22,
        headerTrackingDelta: 0.30,
        headerLineSpacingMultiplier: 1.04,
        headerTopSpace: 15,
        headerBottomSpace: 22,
        runningHeaderPointSize: 9,
        ruleThickness: 0.7,
        ruleLengthFraction: 0.82,
        ruleGap: 10,
        printWear: PrintWearProfile(
            id: "wear.trial1827.v0.1",
            headerWear: 0.14,
            bodyWear: 0.026,
            strokeStarvation: 0.13,
            edgeErosion: 0.11,
            darkDeposit: 0.07,
            seedSalt: 829
        )
    )

    public static let farewell = ReaderCompositionProfile(
        id: "composition.farewell1827.v0.1",
        displayName: "Farewell Address 1827",
        openingInsets: ReaderCompositionInsets(top: 104, leading: 44, bottom: 66, trailing: 44),
        continuationInsets: ReaderCompositionInsets(top: 62, leading: 44, bottom: 62, trailing: 44),
        bodyLeadingMultiplier: 1.18,
        paragraphIndent: 0,
        paragraphGap: 3,
        headerScale: 1.20,
        headerTrackingDelta: 0.25,
        headerLineSpacingMultiplier: 1.10,
        headerTopSpace: 26,
        headerBottomSpace: 34,
        runningHeaderPointSize: 8.5,
        ruleThickness: 0,
        ruleLengthFraction: 0.44,
        ruleGap: 14,
        printWear: PrintWearProfile(
            id: "wear.farewell1827.v0.1",
            headerWear: 0.10,
            bodyWear: 0.018,
            strokeStarvation: 0.09,
            edgeErosion: 0.08,
            darkDeposit: 0.05,
            seedSalt: 839
        )
    )

    public static let all: [ReaderCompositionProfile] = [
        argus,
        dailyAdvertiser,
        confession,
        trial,
        farewell
    ]

    public static func profile(id: String) -> ReaderCompositionProfile? {
        all.first { $0.id == id }
    }

    public static func profile(for unit: ReadingUnit) -> ReaderCompositionProfile {
        switch unit.materialProfile.id {
        case MaterialProfile.argus1827.id: return argus
        case MaterialProfile.dailyAdvertiser1827.id: return dailyAdvertiser
        case MaterialProfile.confessionPamphlet1827.id: return confession
        case MaterialProfile.trialRecord1827.id: return trial
        case MaterialProfile.farewell1827.id: return farewell
        default: return trial
        }
    }
}
