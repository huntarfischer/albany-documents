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

/// Debug-time composition overrides used by the Stage 7.75 Reader Workshop.
/// Scroll and Pages already resolve their shared composition through this catalog,
/// so an override immediately exercises the production rendering path in both.
public final class ReaderCompositionTuningRegistry: @unchecked Sendable {
    public static let shared = ReaderCompositionTuningRegistry()

    private let lock = NSLock()
    private var overrides: [String: ReaderCompositionProfile] = [:]

    private init() {}

    public func profile(id: String) -> ReaderCompositionProfile? {
        lock.lock()
        defer { lock.unlock() }
        return overrides[id]
    }

    public func set(_ profile: ReaderCompositionProfile) {
        lock.lock()
        overrides[profile.id] = profile
        lock.unlock()
    }

    public func remove(id: String) {
        lock.lock()
        overrides.removeValue(forKey: id)
        lock.unlock()
    }

    public func removeAll() {
        lock.lock()
        overrides.removeAll()
        lock.unlock()
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
        headerTopSpace: 8,
        headerBottomSpace: 18,
        runningHeaderPointSize: 9.5,
        ruleThickness: 0.8,
        ruleLengthFraction: 0.88,
        ruleGap: 7,
        printWear: PrintWearProfile(
            id: "wear.argus1827.v0.1",
            headerWear: 0.14,
            bodyWear: 0.040,
            strokeStarvation: 0.10,
            edgeErosion: 0.08,
            darkDeposit: 0,
            seedSalt: 811,
            wearScale: 0.48,
            starvationCap: 0.10,
            erosionCap: 0.08,
            inkOpacity: 0.94,
            usesMultiplyBlend: true,
            datePointScale: 0.68,
            sourceHeaderPointScale: 1.0,
            sectionTitlePointScale: 0.88,
            dateTrackingAdjustment: -0.25,
            sourceHeaderTrackingAdjustment: -0.20,
            sectionTitleTrackingAdjustment: -0.45,
            sourceHeaderLineSpacingOverride: -1.5
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
        id: "composition.farewell1827.v0.2",
        displayName: "Farewell Broadside 1827",
        openingInsets: ReaderCompositionInsets(top: 96, leading: 42, bottom: 72, trailing: 42),
        continuationInsets: ReaderCompositionInsets(top: 64, leading: 42, bottom: 66, trailing: 42),
        bodyLeadingMultiplier: 1.08,
        paragraphIndent: 0,
        paragraphGap: 2,
        headerScale: 1.34,
        headerTrackingDelta: 0.38,
        headerLineSpacingMultiplier: 1.04,
        headerTopSpace: 30,
        headerBottomSpace: 42,
        runningHeaderPointSize: 8.5,
        ruleThickness: 0,
        ruleLengthFraction: 0.36,
        ruleGap: 18,
        printWear: PrintWearProfile(
            id: "wear.farewell1827.v0.2",
            headerWear: 0.22,
            bodyWear: 0.032,
            strokeStarvation: 0.16,
            edgeErosion: 0.14,
            darkDeposit: 0.08,
            seedSalt: 839
        )
    )

    // Stage 9 Book 1.0 keeps the established renderer and adds only the missing
    // documentary character required by the approved visual map.
    public static let historicalBook = ReaderCompositionProfile(
        id: "composition.historicalBook.v0.1",
        displayName: "Historical Book Excerpt",
        openingInsets: ReaderCompositionInsets(top: 72, leading: 36, bottom: 56, trailing: 36),
        continuationInsets: ReaderCompositionInsets(top: 46, leading: 36, bottom: 52, trailing: 36),
        bodyLeadingMultiplier: 1.10,
        paragraphIndent: 14,
        paragraphGap: 2.5,
        headerScale: 1.18,
        headerTrackingDelta: 0.18,
        headerLineSpacingMultiplier: 1.04,
        headerTopSpace: 18,
        headerBottomSpace: 24,
        runningHeaderPointSize: 8.5,
        ruleThickness: 0.45,
        ruleLengthFraction: 0.42,
        ruleGap: 10,
        printWear: PrintWearProfile(
            id: "wear.historicalBook.v0.1",
            headerWear: 0.06,
            bodyWear: 0.014,
            strokeStarvation: 0.04,
            edgeErosion: 0.03,
            darkDeposit: 0.02,
            seedSalt: 853
        )
    )

    public static let officialDocument = ReaderCompositionProfile(
        id: "composition.officialDocument.v0.1",
        displayName: "Official Document",
        openingInsets: ReaderCompositionInsets(top: 70, leading: 34, bottom: 54, trailing: 34),
        continuationInsets: ReaderCompositionInsets(top: 46, leading: 34, bottom: 50, trailing: 34),
        bodyLeadingMultiplier: 1.06,
        paragraphIndent: 10,
        paragraphGap: 2,
        headerScale: 1.16,
        headerTrackingDelta: 0.22,
        headerLineSpacingMultiplier: 1.03,
        headerTopSpace: 16,
        headerBottomSpace: 22,
        runningHeaderPointSize: 8.5,
        ruleThickness: 0.55,
        ruleLengthFraction: 0.72,
        ruleGap: 9,
        printWear: PrintWearProfile(
            id: "wear.officialDocument.v0.1",
            headerWear: 0.05,
            bodyWear: 0.012,
            strokeStarvation: 0.035,
            edgeErosion: 0.025,
            darkDeposit: 0.015,
            seedSalt: 857
        )
    )

    public static let correspondence = ReaderCompositionProfile(
        id: "composition.correspondence.v0.1",
        displayName: "Correspondence",
        openingInsets: ReaderCompositionInsets(top: 76, leading: 40, bottom: 60, trailing: 40),
        continuationInsets: ReaderCompositionInsets(top: 52, leading: 40, bottom: 56, trailing: 40),
        bodyLeadingMultiplier: 1.12,
        paragraphIndent: 0,
        paragraphGap: 4,
        headerScale: 1.08,
        headerTrackingDelta: 0.08,
        headerLineSpacingMultiplier: 1.03,
        headerTopSpace: 18,
        headerBottomSpace: 24,
        runningHeaderPointSize: 8.5,
        ruleThickness: 0,
        ruleLengthFraction: 0.40,
        ruleGap: 10,
        printWear: PrintWearProfile(
            id: "wear.correspondence.v0.1",
            headerWear: 0.035,
            bodyWear: 0.010,
            strokeStarvation: 0.025,
            edgeErosion: 0.020,
            darkDeposit: 0.010,
            seedSalt: 859
        )
    )

    public static let newspaper1905 = ReaderCompositionProfile(
        id: "composition.newspaper1905.v0.1",
        displayName: "Newspaper 1905",
        openingInsets: ReaderCompositionInsets(top: 60, leading: 30, bottom: 50, trailing: 30),
        continuationInsets: ReaderCompositionInsets(top: 42, leading: 30, bottom: 46, trailing: 30),
        bodyLeadingMultiplier: 1.06,
        paragraphIndent: 10,
        paragraphGap: 1.5,
        headerScale: 1.18,
        headerTrackingDelta: 0.20,
        headerLineSpacingMultiplier: 1.03,
        headerTopSpace: 12,
        headerBottomSpace: 18,
        runningHeaderPointSize: 9,
        ruleThickness: 0.65,
        ruleLengthFraction: 0.80,
        ruleGap: 8,
        printWear: PrintWearProfile(
            id: "wear.newspaper1905.v0.1",
            headerWear: 0.08,
            bodyWear: 0.022,
            strokeStarvation: 0.06,
            edgeErosion: 0.05,
            darkDeposit: 0.02,
            seedSalt: 863
        )
    )

    public static let newspaper1967 = ReaderCompositionProfile(
        id: "composition.newspaper1967.v0.1",
        displayName: "Newspaper 1967",
        openingInsets: ReaderCompositionInsets(top: 56, leading: 30, bottom: 48, trailing: 30),
        continuationInsets: ReaderCompositionInsets(top: 40, leading: 30, bottom: 44, trailing: 30),
        bodyLeadingMultiplier: 1.04,
        paragraphIndent: 10,
        paragraphGap: 2,
        headerScale: 1.12,
        headerTrackingDelta: 0.12,
        headerLineSpacingMultiplier: 1.02,
        headerTopSpace: 10,
        headerBottomSpace: 16,
        runningHeaderPointSize: 9,
        ruleThickness: 0.50,
        ruleLengthFraction: 0.78,
        ruleGap: 7,
        printWear: PrintWearProfile(
            id: "wear.newspaper1967.v0.1",
            headerWear: 0.025,
            bodyWear: 0.006,
            strokeStarvation: 0.018,
            edgeErosion: 0.012,
            darkDeposit: 0.006,
            seedSalt: 877
        )
    )

    public static let referenceBackMatter = ReaderCompositionProfile(
        id: "composition.referenceBackMatter.v0.1",
        displayName: "Reference Back Matter",
        openingInsets: ReaderCompositionInsets(top: 58, leading: 36, bottom: 48, trailing: 36),
        continuationInsets: ReaderCompositionInsets(top: 40, leading: 36, bottom: 44, trailing: 36),
        bodyLeadingMultiplier: 1.06,
        paragraphIndent: 0,
        paragraphGap: 3,
        headerScale: 1.12,
        headerTrackingDelta: 0.12,
        headerLineSpacingMultiplier: 1.02,
        headerTopSpace: 14,
        headerBottomSpace: 18,
        runningHeaderPointSize: 8.5,
        ruleThickness: 0.35,
        ruleLengthFraction: 0.48,
        ruleGap: 8,
        printWear: PrintWearProfile(
            id: "wear.referenceBackMatter.v0.1",
            headerWear: 0.015,
            bodyWear: 0.004,
            strokeStarvation: 0.010,
            edgeErosion: 0.008,
            darkDeposit: 0.004,
            seedSalt: 881
        )
    )

    public static let all: [ReaderCompositionProfile] = [
        argus,
        dailyAdvertiser,
        confession,
        trial,
        farewell,
        historicalBook,
        officialDocument,
        correspondence,
        newspaper1905,
        newspaper1967,
        referenceBackMatter
    ]

    public static func bundledProfile(id: String) -> ReaderCompositionProfile? {
        all.first { $0.id == id }
    }

    public static func profile(id: String) -> ReaderCompositionProfile? {
        ReaderCompositionTuningRegistry.shared.profile(id: id) ?? bundledProfile(id: id)
    }

    public static func bundledProfile(for unit: ReadingUnit) -> ReaderCompositionProfile {
        switch unit.materialProfile.id {
        case MaterialProfile.argus1827.id: return argus
        case MaterialProfile.dailyAdvertiser1827.id: return dailyAdvertiser
        case MaterialProfile.confessionPamphlet1827.id: return confession
        case MaterialProfile.trialRecord1827.id: return trial
        case MaterialProfile.farewell1827.id: return farewell
        case "historicalBook": return historicalBook
        case "officialDocument": return officialDocument
        case "correspondence": return correspondence
        case "newspaper1905": return newspaper1905
        case "newspaper1967": return newspaper1967
        case "referenceBackMatter": return referenceBackMatter
        default: return trial
        }
    }

    public static func profile(for unit: ReadingUnit) -> ReaderCompositionProfile {
        let base = bundledProfile(for: unit)
        return ReaderCompositionTuningRegistry.shared.profile(id: base.id) ?? base
    }
}
