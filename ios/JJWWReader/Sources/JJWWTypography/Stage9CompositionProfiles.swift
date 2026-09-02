import Foundation
import JJWWReaderCore

public extension ReaderCompositionCatalog {
    static let editorial = ReaderCompositionProfile(
        id: "composition.jjwwEditorial.v0.1",
        displayName: "Editorial Interstitial",
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
            id: "wear.jjwwEditorial.v0.1",
            headerWear: 0.14,
            bodyWear: 0.026,
            strokeStarvation: 0.13,
            edgeErosion: 0.11,
            darkDeposit: 0.07,
            seedSalt: 829
        )
    )

    /// One family-level newspaper composition. The Argus geometry is the proven
    /// baseline; publication-specific refinement is applied after tuning so one
    /// Workshop control can still govern the full 1827 newspaper family.
    static let newspaper1827 = ReaderCompositionProfile(
        id: "composition.newspaper1827.v0.1",
        displayName: "Newspaper 1827",
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

    static let publishedAccount = ReaderCompositionProfile(
        id: "composition.publishedAccountPamphlet.v0.1",
        displayName: "Published Account Pamphlet",
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
            id: "wear.publishedAccountPamphlet.v0.1",
            headerWear: 0.16,
            bodyWear: 0.032,
            strokeStarvation: 0.16,
            edgeErosion: 0.14,
            darkDeposit: 0.08,
            seedSalt: 823
        )
    )

    static let displayArtifact = ReaderCompositionProfile(
        id: "composition.displayArtifact.v0.1",
        displayName: "Display Artifact · Verse / Broadside",
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
            id: "wear.displayArtifact.v0.1",
            headerWear: 0.22,
            bodyWear: 0.032,
            strokeStarvation: 0.16,
            edgeErosion: 0.14,
            darkDeposit: 0.08,
            seedSalt: 839
        )
    )

    /// Retains the Daily Advertiser's existing publication character while keeping
    /// the shared family composition ID. Values are expressed as deltas from the
    /// tunable 1827 baseline, so family Workshop changes still flow through.
    static func applyingSourceVariant(
        to profile: ReaderCompositionProfile,
        for unit: ReadingUnit
    ) -> ReaderCompositionProfile {
        guard unit.presentationVariant == "dailyAdvertiser1827" else {
            return profile
        }

        var adjusted = profile
        adjusted.openingInsets.top += 4
        adjusted.openingInsets.leading += 2
        adjusted.openingInsets.bottom += 2
        adjusted.openingInsets.trailing += 2
        adjusted.continuationInsets.top += 2
        adjusted.continuationInsets.leading += 2
        adjusted.continuationInsets.trailing += 2
        adjusted.bodyLeadingMultiplier -= 0.01
        adjusted.headerScale -= 0.04
        adjusted.headerTrackingDelta -= 0.07
        adjusted.headerLineSpacingMultiplier -= 0.02
        adjusted.headerTopSpace += 6
        adjusted.headerBottomSpace += 4
        adjusted.ruleThickness -= 0.05
        adjusted.ruleLengthFraction -= 0.02
        adjusted.ruleGap += 3

        let baseWear = profile.printWear
        let dailyStroke = baseWear.strokeStarvation + 0.10
        let dailyErosion = baseWear.edgeErosion + 0.08
        adjusted.printWear = PrintWearProfile(
            id: "wear.dailyAdvertiser1827.v0.1",
            headerWear: baseWear.headerWear + 0.04,
            bodyWear: baseWear.bodyWear,
            strokeStarvation: dailyStroke,
            edgeErosion: dailyErosion,
            darkDeposit: baseWear.darkDeposit + 0.09,
            seedSalt: baseWear.seedSalt &+ 6,
            wearScale: (baseWear.wearScale ?? 0.48) + 0.52,
            starvationCap: dailyStroke,
            erosionCap: dailyErosion,
            inkOpacity: min(1, (baseWear.inkOpacity ?? 0.94) + 0.06),
            usesMultiplyBlend: false,
            datePointScale: (baseWear.datePointScale ?? 0.68) + 0.32,
            sourceHeaderPointScale: baseWear.sourceHeaderPointScale ?? 1.0,
            sectionTitlePointScale: (baseWear.sectionTitlePointScale ?? 0.88) + 0.12,
            dateTrackingAdjustment: (baseWear.dateTrackingAdjustment ?? -0.25) + 0.25,
            sourceHeaderTrackingAdjustment: (baseWear.sourceHeaderTrackingAdjustment ?? -0.20) + 0.20,
            sectionTitleTrackingAdjustment: (baseWear.sectionTitleTrackingAdjustment ?? -0.45) + 0.45,
            sourceHeaderLineSpacingOverride: (baseWear.sourceHeaderLineSpacingOverride ?? -1.5) + 1.5
        )
        return adjusted
    }
}
