import Foundation
import JJWWReaderCore
import JJWWTypography
import JJWWScrollReader

public enum PageTypographyResolver {
    public static func pointScale(for textScale: ReaderTextScale) -> Double {
        switch textScale {
        case .standard: return 1
        case .large: return 1.18
        case .accessibility: return 1.55
        }
    }

    public static func resolve(
        text: String,
        canonicalLine: Int,
        role: TypographyRole,
        unit: ReadingUnit,
        textScale: ReaderTextScale,
        isOpeningHeader: Bool,
        isFirstOpeningHeader: Bool,
        isLastOpeningHeader: Bool
    ) -> ResolvedReaderTypography? {
        guard let typography = TypographyCatalog.profile(id: unit.typographyProfile.id) else {
            return nil
        }

        let composition = ReaderCompositionCatalog.profile(for: unit)
        let scale = pointScale(for: textScale)

        if unit.id == FarewellArtifactLayout.unitID {
            return resolveFarewell(
                text: text,
                canonicalLine: canonicalLine,
                role: role,
                typography: typography,
                composition: composition,
                textScale: scale,
                isOpeningHeader: isOpeningHeader,
                isFirstOpeningHeader: isFirstOpeningHeader,
                isLastOpeningHeader: isLastOpeningHeader
            )
        }

        return ReaderTypographyGeometryResolver.resolveLine(
            text: text,
            token: typography.token(role),
            composition: composition,
            textScale: scale,
            isOpeningHeader: isOpeningHeader,
            isFirstOpeningHeader: isFirstOpeningHeader,
            isLastOpeningHeader: isLastOpeningHeader
        )
    }

    private static func resolveFarewell(
        text: String,
        canonicalLine: Int,
        role: TypographyRole,
        typography: TypographyProfileDefinition,
        composition: ReaderCompositionProfile,
        textScale: Double,
        isOpeningHeader: Bool,
        isFirstOpeningHeader: Bool,
        isLastOpeningHeader: Bool
    ) -> ResolvedReaderTypography {
        if FarewellArtifactLayout.headerRange.contains(canonicalLine) {
            let token: TypographyToken
            let pointScale: Double
            let trackingDelta: Double
            let before: Double
            let after: Double

            if canonicalLine == 1893 {
                token = typography.token(.sourceHeader)
                pointScale = textScale * 0.98
                trackingDelta = 0
                before = 0
                after = 5 * textScale
            } else if canonicalLine == 1894 {
                token = typography.token(.dateHeading)
                pointScale = textScale * 0.90
                trackingDelta = 0
                before = 0
                after = composition.headerBottomSpace * textScale
            } else {
                token = typography.token(.sectionTitle)
                pointScale = textScale * composition.headerScale
                trackingDelta = composition.headerTrackingDelta
                before = isFirstOpeningHeader
                    ? composition.headerTopSpace * textScale
                    : 0
                after = 12 * textScale
            }

            return ReaderTypographyGeometryResolver.resolveLine(
                text: text,
                token: token,
                composition: composition,
                textScale: textScale,
                isOpeningHeader: isOpeningHeader,
                isFirstOpeningHeader: isFirstOpeningHeader,
                isLastOpeningHeader: isLastOpeningHeader,
                pointScaleOverride: pointScale,
                trackingDeltaOverride: trackingDelta,
                lineSpacingMultiplierOverride: composition.headerLineSpacingMultiplier,
                paragraphSpacingBeforeOverride: before,
                paragraphSpacingAfterOverride: after,
                followingDecorationHeightOverride: 0,
                firstLineHeadIndentOverride: 0
            )
        }

        if FarewellArtifactLayout.columnSide(for: canonicalLine) != nil {
            let before = canonicalLine == FarewellArtifactLayout.secondColumnStart
                ? 34 * textScale
                : 0
            let after = FarewellArtifactLayout.isStanzaEnd(canonicalLine)
                ? 12 * textScale
                : 1.5 * textScale
            return ReaderTypographyGeometryResolver.resolveLine(
                text: text,
                token: typography.token(.verse),
                composition: composition,
                textScale: textScale,
                isOpeningHeader: false,
                isFirstOpeningHeader: false,
                isLastOpeningHeader: false,
                pointScaleOverride: textScale,
                trackingDeltaOverride: 0,
                lineSpacingMultiplierOverride: composition.bodyLeadingMultiplier,
                paragraphSpacingBeforeOverride: before,
                paragraphSpacingAfterOverride: after,
                followingDecorationHeightOverride: 0,
                firstLineHeadIndentOverride: 0
            )
        }

        return ReaderTypographyGeometryResolver.resolveLine(
            text: text,
            token: typography.token(role),
            composition: composition,
            textScale: textScale,
            isOpeningHeader: isOpeningHeader,
            isFirstOpeningHeader: isFirstOpeningHeader,
            isLastOpeningHeader: isLastOpeningHeader
        )
    }
}
