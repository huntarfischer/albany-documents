import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The single geometry contract shared by pagination measurement and Pages rendering.
/// Canonical text remains owned by ReaderCore; this describes only how that text is laid out.
public struct ResolvedPrintTypography: Codable, Equatable, Sendable {
    public let displayText: String
    public let pointScale: Double
    public let tracking: Double
    public let lineSpacing: Double

    public init(
        displayText: String,
        pointScale: Double,
        tracking: Double,
        lineSpacing: Double
    ) {
        self.displayText = displayText
        self.pointScale = pointScale
        self.tracking = tracking
        self.lineSpacing = lineSpacing
    }
}

public struct ResolvedReaderTypography: Codable, Equatable, Sendable {
    public let token: TypographyToken
    public let displayText: String
    public let pointSize: Double
    public let tracking: Double
    public let lineSpacing: Double
    public let paragraphSpacingBefore: Double
    public let paragraphSpacingAfter: Double
    public let followingDecorationHeight: Double
    public let firstLineHeadIndent: Double

    public init(
        token: TypographyToken,
        displayText: String,
        pointSize: Double,
        tracking: Double,
        lineSpacing: Double,
        paragraphSpacingBefore: Double,
        paragraphSpacingAfter: Double,
        followingDecorationHeight: Double = 0,
        firstLineHeadIndent: Double = 0
    ) {
        self.token = token
        self.displayText = displayText
        self.pointSize = pointSize
        self.tracking = tracking
        self.lineSpacing = lineSpacing
        self.paragraphSpacingBefore = paragraphSpacingBefore
        self.paragraphSpacingAfter = paragraphSpacingAfter
        self.followingDecorationHeight = followingDecorationHeight
        self.firstLineHeadIndent = firstLineHeadIndent
    }

    public var totalParagraphSpacingAfter: Double {
        paragraphSpacingAfter + followingDecorationHeight
    }

    /// The paginator measures a complete canonical paragraph, while a PageSlice
    /// may render only the continuation fragment of that paragraph. Suppress
    /// paragraph-edge geometry on interior fragments so Pages does not add a
    /// fresh indent or paragraph gap at a physical page boundary.
    public func renderingFragment(
        startsCanonicalLine: Bool,
        endsCanonicalLine: Bool
    ) -> ResolvedReaderTypography {
        ResolvedReaderTypography(
            token: token,
            displayText: displayText,
            pointSize: pointSize,
            tracking: tracking,
            lineSpacing: lineSpacing,
            paragraphSpacingBefore: startsCanonicalLine ? paragraphSpacingBefore : 0,
            paragraphSpacingAfter: endsCanonicalLine ? paragraphSpacingAfter : 0,
            followingDecorationHeight: endsCanonicalLine ? followingDecorationHeight : 0,
            firstLineHeadIndent: startsCanonicalLine ? firstLineHeadIndent : 0
        )
    }

    public var swiftUIFont: Font {
        if let family = token.fontFamily {
            return .custom(family, size: CGFloat(pointSize))
                .weight(token.weight.swiftUIWeight)
        }
        return .system(
            size: CGFloat(pointSize),
            weight: token.weight.swiftUIWeight,
            design: token.design.swiftUIDesign
        )
    }

    #if canImport(UIKit)
    public var platformFont: UIFont {
        let weight: UIFont.Weight
        switch token.weight {
        case .regular: weight = .regular
        case .medium: weight = .medium
        case .semibold: weight = .semibold
        case .bold: weight = .bold
        case .black: weight = .black
        }

        if let family = token.fontFamily,
           let custom = UIFont(name: family, size: CGFloat(pointSize)) {
            let descriptor = custom.fontDescriptor.addingAttributes([
                .traits: [UIFontDescriptor.TraitKey.weight: weight]
            ])
            return UIFont(descriptor: descriptor, size: CGFloat(pointSize))
        }

        let base = UIFont.systemFont(ofSize: CGFloat(pointSize), weight: weight)
        let design: UIFontDescriptor.SystemDesign
        switch token.design {
        case .serif: design = .serif
        case .rounded: design = .rounded
        case .monospaced: design = .monospaced
        case .system: design = .default
        }
        if let descriptor = base.fontDescriptor.withDesign(design) {
            return UIFont(descriptor: descriptor, size: CGFloat(pointSize))
        }
        return base
    }
    #elseif canImport(AppKit)
    public var platformFont: NSFont {
        if let family = token.fontFamily,
           let custom = NSFont(name: family, size: CGFloat(pointSize)) {
            let manager = NSFontManager.shared
            switch token.weight {
            case .bold, .black, .semibold:
                return manager.convert(custom, toHaveTrait: .boldFontMask)
            case .regular, .medium:
                return custom
            }
        }

        if token.design == .serif {
            let name: String
            switch token.weight {
            case .bold, .black, .semibold: name = "Times New Roman Bold"
            default: name = "Times New Roman"
            }
            return NSFont(name: name, size: CGFloat(pointSize))
                ?? NSFont.systemFont(ofSize: CGFloat(pointSize))
        }

        if token.design == .monospaced {
            return NSFont.monospacedSystemFont(
                ofSize: CGFloat(pointSize),
                weight: .regular
            )
        }

        let weight: NSFont.Weight
        switch token.weight {
        case .regular: weight = .regular
        case .medium: weight = .medium
        case .semibold: weight = .semibold
        case .bold: weight = .bold
        case .black: weight = .black
        }
        return NSFont.systemFont(ofSize: CGFloat(pointSize), weight: weight)
    }
    #endif

    #if canImport(UIKit) || canImport(AppKit)
    public var attributedStringAttributes: [NSAttributedString.Key: Any] {
        attributedStringAttributes(includeExternalParagraphSpacing: true)
    }

    /// Pages supplies paragraph-before/after spacing as SwiftUI geometry so the
    /// rule and paper composition can participate in the same stack. The live
    /// TextKit-backed text view therefore uses the exact font/leading/indent but
    /// does not apply those outer spacings a second time.
    public var renderingAttributedStringAttributes: [NSAttributedString.Key: Any] {
        attributedStringAttributes(includeExternalParagraphSpacing: false)
    }

    private func attributedStringAttributes(
        includeExternalParagraphSpacing: Bool
    ) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        switch token.paragraphAlignment {
        case .leading:
            paragraph.alignment = .left
        case .centered:
            paragraph.alignment = .center
        case .justified:
            paragraph.alignment = .justified
        }
        paragraph.hyphenationFactor = Float(token.hyphenationFactor)
        paragraph.lineSpacing = CGFloat(lineSpacing)
        paragraph.paragraphSpacingBefore = includeExternalParagraphSpacing
            ? CGFloat(paragraphSpacingBefore)
            : 0
        paragraph.paragraphSpacing = includeExternalParagraphSpacing
            ? CGFloat(totalParagraphSpacingAfter)
            : 0
        paragraph.firstLineHeadIndent = CGFloat(firstLineHeadIndent)

        return [
            .font: platformFont,
            .kern: CGFloat(tracking),
            .paragraphStyle: paragraph
        ]
    }
    #endif
}

public enum ReaderTypographyGeometryResolver {
    public static func resolvePrintGeometry(
        text: String,
        token: TypographyToken,
        profile: PrintWearProfile,
        pointScale: Double = 1,
        trackingDelta: Double = 0,
        lineSpacingMultiplier: Double = 1
    ) -> ResolvedPrintTypography {
        let argus = profile.id.hasPrefix("wear.argus1827")
        let rolePointScale: Double
        let roleTrackingAdjustment: Double

        switch token.role {
        case .dateHeading:
            rolePointScale = profile.datePointScale ?? (argus ? 0.68 : 1)
            roleTrackingAdjustment = profile.dateTrackingAdjustment ?? (argus ? -0.25 : 0)
        case .sourceHeader:
            rolePointScale = profile.sourceHeaderPointScale ?? 1
            roleTrackingAdjustment = profile.sourceHeaderTrackingAdjustment ?? (argus ? -0.20 : 0)
        case .sectionTitle:
            rolePointScale = profile.sectionTitlePointScale ?? (argus ? 0.88 : 1)
            roleTrackingAdjustment = profile.sectionTitleTrackingAdjustment ?? (argus ? -trackingDelta : 0)
        default:
            rolePointScale = 1
            roleTrackingAdjustment = 0
        }

        let lineSpacing: Double
        if token.role == .sourceHeader,
           let override = profile.sourceHeaderLineSpacingOverride {
            lineSpacing = override
        } else if argus, token.role == .sourceHeader {
            lineSpacing = -1.5
        } else {
            lineSpacing = token.lineSpacing * lineSpacingMultiplier
        }

        let canonicalRendered = token.uppercase ? text.uppercased() : text
        let displayText: String
        if argus,
           token.role == .sourceHeader,
           canonicalRendered == "THE ALBANY ARGUS & CITY GAZETTE" {
            // One character is replaced, not inserted, so canonical UTF-16 offsets remain 1:1.
            displayText = "THE ALBANY ARGUS\n& CITY GAZETTE"
        } else {
            displayText = canonicalRendered
        }

        return ResolvedPrintTypography(
            displayText: displayText,
            pointScale: pointScale * rolePointScale,
            tracking: token.tracking + trackingDelta + roleTrackingAdjustment,
            lineSpacing: lineSpacing
        )
    }

    public static func resolveLine(
        text: String,
        token: TypographyToken,
        composition: ReaderCompositionProfile,
        textScale: Double,
        isOpeningHeader: Bool,
        isFirstOpeningHeader: Bool,
        isLastOpeningHeader: Bool,
        pointScaleOverride: Double? = nil,
        trackingDeltaOverride: Double? = nil,
        lineSpacingMultiplierOverride: Double? = nil,
        paragraphSpacingBeforeOverride: Double? = nil,
        paragraphSpacingAfterOverride: Double? = nil,
        followingDecorationHeightOverride: Double? = nil,
        firstLineHeadIndentOverride: Double? = nil
    ) -> ResolvedReaderTypography {
        let basePointScale = pointScaleOverride
            ?? textScale * (isOpeningHeader ? composition.headerScale : 1)
        let trackingDelta = trackingDeltaOverride
            ?? (isOpeningHeader ? composition.headerTrackingDelta : 0)
        let leadingMultiplier = lineSpacingMultiplierOverride
            ?? (isOpeningHeader
                ? composition.headerLineSpacingMultiplier
                : composition.bodyLeadingMultiplier)

        let print = resolvePrintGeometry(
            text: text,
            token: token,
            profile: composition.printWear,
            pointScale: basePointScale,
            trackingDelta: trackingDelta,
            lineSpacingMultiplier: leadingMultiplier
        )

        let before = paragraphSpacingBeforeOverride
            ?? (isFirstOpeningHeader ? composition.headerTopSpace * textScale : 0)
        let after = paragraphSpacingAfterOverride
            ?? defaultParagraphSpacingAfter(
                for: token.role,
                composition: composition,
                textScale: textScale
            )
        let decoration = followingDecorationHeightOverride
            ?? (isLastOpeningHeader && composition.ruleThickness > 0
                ? (
                    composition.ruleGap
                    + max(0.5, composition.ruleThickness)
                    + composition.headerBottomSpace * 0.45
                ) * textScale
                : 0)
        let indent = firstLineHeadIndentOverride
            ?? (token.justified && bodyRole(token.role)
                ? composition.paragraphIndent * textScale
                : 0)

        return ResolvedReaderTypography(
            token: token,
            displayText: print.displayText,
            pointSize: typographyBasePointSize(for: token.textStyle)
                * max(0.60, print.pointScale),
            tracking: print.tracking,
            lineSpacing: print.lineSpacing,
            paragraphSpacingBefore: before,
            paragraphSpacingAfter: after,
            followingDecorationHeight: decoration,
            firstLineHeadIndent: indent
        )
    }

    public static func defaultParagraphSpacingAfter(
        for role: TypographyRole,
        composition: ReaderCompositionProfile,
        textScale: Double
    ) -> Double {
        let unscaled: Double
        switch role {
        case .dateHeading, .sourceHeader:
            unscaled = 7
        case .sectionTitle:
            unscaled = composition.ruleThickness > 0
                ? 2
                : composition.headerBottomSpace
        case .verse:
            unscaled = 3
        case .body, .firstPersonBody:
            unscaled = composition.paragraphGap
        default:
            unscaled = 2
        }
        return unscaled * textScale
    }

    private static func bodyRole(_ role: TypographyRole) -> Bool {
        role == .body || role == .firstPersonBody
    }
}

public func typographyBasePointSize(
    for style: TypographyDynamicTextStyle
) -> Double {
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
