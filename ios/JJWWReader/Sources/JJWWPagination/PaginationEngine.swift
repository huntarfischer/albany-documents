import Foundation
import CoreGraphics
import JJWWReaderCore
import JJWWTypography
import JJWWScrollReader

#if canImport(UIKit)
import UIKit
private typealias PlatformFont = UIFont
#elseif canImport(AppKit)
import AppKit
private typealias PlatformFont = NSFont
#endif

public enum PaginationError: Error, Equatable {
    case invalidPageGeometry
    case missingTypographyProfile(String)
    case textKitProducedEmptyPage(String)
    case unsupportedPlatform
}

@MainActor
public final class PaginationEngine {
    private let cache: PaginationCache

    public init(cache: PaginationCache) {
        self.cache = cache
    }

    public convenience init() {
        self.init(cache: PaginationCache())
    }

    public func paginate(
        edition: Edition,
        configuration: PaginationConfiguration = PaginationConfiguration()
    ) throws -> PaginationResult {
        guard configuration.geometry.contentWidth > 1,
              configuration.geometry.contentHeight > 1 else {
            throw PaginationError.invalidPageGeometry
        }

        let key = configuration.cacheKey(for: edition)
        if let cached = cache.value(for: key) {
            return cached
        }

        let units = edition.orderedReadingUnits.filter {
            configuration.includeCoverUnit || $0.kind != .cover
        }
        let segments = makeSegments(units: units, rules: configuration.presentationRules)

        var pages: [PageSlice] = []
        var globalPageIndex = 0

        for (segmentIndex, segment) in segments.enumerated() {
            let segmentID = "segment-\(segmentIndex)-\(segment.first?.id ?? "empty")"
            let segmentPages = try paginateSegment(
                segment,
                segmentID: segmentID,
                globalPageIndex: globalPageIndex,
                configuration: configuration
            )
            pages.append(contentsOf: segmentPages)
            globalPageIndex += segmentPages.count
        }

        let result = PaginationResult(configuration: configuration, cacheKey: key, pages: pages)
        cache.store(result)
        return result
    }

    private func makeSegments(
        units: [ReadingUnit],
        rules: PaginationPresentationRules
    ) -> [[ReadingUnit]] {
        guard let first = units.first else { return [] }
        var segments: [[ReadingUnit]] = [[first]]

        for unit in units.dropFirst() {
            guard let previous = segments.last?.last else {
                segments.append([unit])
                continue
            }
            if rules.requiresNewLeaf(between: previous, and: unit) {
                segments.append([unit])
            } else {
                segments[segments.count - 1].append(unit)
            }
        }
        return segments
    }

    private func paginateSegment(
        _ units: [ReadingUnit],
        segmentID: String,
        globalPageIndex: Int,
        configuration: PaginationConfiguration
    ) throws -> [PageSlice] {
        guard let firstUnit = units.first else { return [] }
        guard let profile = TypographyCatalog.profile(id: firstUnit.typographyProfile.id) else {
            throw PaginationError.missingTypographyProfile(firstUnit.typographyProfile.id)
        }

        let source = buildAttributedSource(
            units: units,
            typographyProfile: profile,
            textScale: configuration.textScale
        )

        #if canImport(UIKit) || canImport(AppKit)
        let textStorage = NSTextStorage(attributedString: source.attributedString)
        let layoutManager = NSLayoutManager()
        layoutManager.usesFontLeading = true
        textStorage.addLayoutManager(layoutManager)

        var containers: [NSTextContainer] = []
        var pageCharacterRanges: [NSRange] = []
        var coveredCharacters = 0
        var guardCount = 0

        while coveredCharacters < source.attributedString.length {
            guardCount += 1
            if guardCount > 10_000 {
                throw PaginationError.textKitProducedEmptyPage(segmentID)
            }

            let container = NSTextContainer(size: configuration.geometry.contentSize)
            container.lineFragmentPadding = 0
            layoutManager.addTextContainer(container)
            layoutManager.ensureLayout(for: container)

            let glyphRange = layoutManager.glyphRange(for: container)
            let characterRange = layoutManager.characterRange(
                forGlyphRange: glyphRange,
                actualGlyphRange: nil
            )
            guard characterRange.length > 0 else {
                throw PaginationError.textKitProducedEmptyPage(segmentID)
            }

            containers.append(container)
            pageCharacterRanges.append(characterRange)
            coveredCharacters = max(coveredCharacters, NSMaxRange(characterRange))
        }

        var result: [PageSlice] = []
        for (localPageIndex, characterRange) in pageCharacterRanges.enumerated() {
            let fragments = fragments(for: characterRange, records: source.lineRecords)
            guard let firstFragment = fragments.first,
                  let lastFragment = fragments.last else {
                continue
            }

            let readingUnitIDs = fragments.reduce(into: [String]()) { ids, fragment in
                if !ids.contains(fragment.readingUnitID) {
                    ids.append(fragment.readingUnitID)
                }
            }
            let pageIndex = globalPageIndex + localPageIndex
            let firstUnitForPage = units.first(where: { $0.id == firstFragment.readingUnitID }) ?? firstUnit
            let startAnchor = ReadingAnchor(
                canonicalLayer0Version: firstUnitForPage.canonicalAnchor.canonicalLayer0Version,
                startLine: firstFragment.canonicalLine,
                endLine: firstFragment.canonicalLine
            )
            let lastUnitForPage = units.first(where: { $0.id == lastFragment.readingUnitID }) ?? firstUnit
            let endAnchor = ReadingAnchor(
                canonicalLayer0Version: lastUnitForPage.canonicalAnchor.canonicalLayer0Version,
                startLine: lastFragment.canonicalLine,
                endLine: lastFragment.canonicalLine
            )
            let startsAtUnitBeginning = units.contains { unit in
                unit.id == firstFragment.readingUnitID &&
                unit.canonicalAnchor.startLine == firstFragment.canonicalLine &&
                firstFragment.utf16Start == 0
            }

            result.append(
                PageSlice(
                    id: "page-\(pageIndex)-\(segmentID)",
                    pageIndex: pageIndex,
                    layoutSegmentID: segmentID,
                    segmentTextRange: PageTextRange(
                        location: characterRange.location,
                        length: characterRange.length
                    ),
                    readingUnitIDs: readingUnitIDs,
                    startAnchor: startAnchor,
                    endAnchor: endAnchor,
                    startLocation: ReaderLocation(
                        readingUnitID: firstFragment.readingUnitID,
                        blockID: firstFragment.blockID,
                        canonicalLine: firstFragment.canonicalLine,
                        utf16OffsetInLine: firstFragment.utf16Start
                    ),
                    endLocationExclusive: ReaderLocation(
                        readingUnitID: lastFragment.readingUnitID,
                        blockID: lastFragment.blockID,
                        canonicalLine: lastFragment.canonicalLine,
                        utf16OffsetInLine: lastFragment.utf16EndExclusive
                    ),
                    fragments: fragments,
                    materialProfile: firstUnitForPage.materialProfile,
                    side: pageIndex.isMultiple(of: 2) ? .recto : .verso,
                    beginsSectionTransition: startsAtUnitBeginning
                )
            )
        }
        return result
        #else
        throw PaginationError.unsupportedPlatform
        #endif
    }

    private struct LineRecord {
        let readingUnitID: String
        let blockID: String
        let canonicalLine: CanonicalLine
        let role: TypographyRole
        let textRange: NSRange
        let separatorLocation: Int?
        let separatorKind: PageTextSeparator
    }

    private struct AttributedSource {
        let attributedString: NSAttributedString
        let lineRecords: [LineRecord]
    }

    private func buildAttributedSource(
        units: [ReadingUnit],
        typographyProfile: TypographyProfileDefinition,
        textScale: ReaderTextScale
    ) -> AttributedSource {
        let output = NSMutableAttributedString(string: "")
        var records: [LineRecord] = []

        let presentations: [(ReadingUnit, DocumentBlock, ReaderLinePresentation)] = units.flatMap { unit in
            unit.blocks.flatMap { block in
                ReaderLineRoleResolver.presentations(for: block, in: unit).map { (unit, block, $0) }
            }
        }

        for (index, item) in presentations.enumerated() {
            let (unit, block, presentation) = item
            let token = typographyProfileFor(unit: unit, fallback: typographyProfile).token(presentation.role)
            let attributes = attributes(for: token, textScale: textScale)
            let start = output.length
            let text = presentation.canonicalLine.text
            output.append(NSAttributedString(string: text, attributes: attributes))
            let textRange = NSRange(location: start, length: (text as NSString).length)

            var separatorLocation: Int?
            var separatorKind: PageTextSeparator = .none
            if index < presentations.count - 1 {
                separatorLocation = output.length
                let next = presentations[index + 1]
                separatorKind = next.0.id == unit.id ? .lineBreak : .readingUnitBreak
                output.append(NSAttributedString(string: "\n", attributes: attributes))
            }

            records.append(
                LineRecord(
                    readingUnitID: unit.id,
                    blockID: block.id,
                    canonicalLine: presentation.canonicalLine,
                    role: presentation.role,
                    textRange: textRange,
                    separatorLocation: separatorLocation,
                    separatorKind: separatorKind
                )
            )
        }

        return AttributedSource(attributedString: output, lineRecords: records)
    }

    private func typographyProfileFor(
        unit: ReadingUnit,
        fallback: TypographyProfileDefinition
    ) -> TypographyProfileDefinition {
        TypographyCatalog.profile(id: unit.typographyProfile.id) ?? fallback
    }

    private func fragments(for pageRange: NSRange, records: [LineRecord]) -> [PageTextFragment] {
        var result: [PageTextFragment] = []

        for record in records {
            let intersection = NSIntersectionRange(pageRange, record.textRange)
            let includesSeparator: Bool
            if let separatorLocation = record.separatorLocation {
                includesSeparator = separatorLocation >= pageRange.location && separatorLocation < NSMaxRange(pageRange)
            } else {
                includesSeparator = false
            }

            guard intersection.length > 0 || includesSeparator else { continue }

            let localStart = max(0, intersection.location - record.textRange.location)
            let localEnd = localStart + intersection.length
            let text: String
            if intersection.length > 0 {
                text = (record.canonicalLine.text as NSString).substring(
                    with: NSRange(location: localStart, length: intersection.length)
                )
            } else {
                text = ""
            }

            result.append(
                PageTextFragment(
                    id: "\(record.readingUnitID).\(record.blockID).\(record.canonicalLine.number).\(localStart)-\(localEnd).\(pageRange.location)",
                    readingUnitID: record.readingUnitID,
                    blockID: record.blockID,
                    canonicalLine: record.canonicalLine.number,
                    utf16Start: localStart,
                    utf16EndExclusive: localEnd,
                    text: text,
                    role: record.role,
                    trailingSeparator: includesSeparator ? record.separatorKind : .none
                )
            )
        }
        return result
    }

    private func attributes(
        for token: TypographyToken,
        textScale: ReaderTextScale
    ) -> [NSAttributedString.Key: Any] {
        #if canImport(UIKit) || canImport(AppKit)
        let scale = pointScale(for: textScale)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = token.centered ? .center : .left
        paragraph.lineSpacing = CGFloat(token.lineSpacing) * scale
        paragraph.paragraphSpacing = paragraphSpacing(for: token.role) * scale

        return [
            .font: platformFont(for: token, scale: scale),
            .kern: CGFloat(token.tracking),
            .paragraphStyle: paragraph
        ]
        #else
        return [:]
        #endif
    }

    private func pointScale(for textScale: ReaderTextScale) -> CGFloat {
        switch textScale {
        case .standard: return 1.0
        case .large: return 1.18
        case .accessibility: return 1.55
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

    private func paragraphSpacing(for role: TypographyRole) -> CGFloat {
        switch role {
        case .dateHeading: return 7
        case .sourceHeader: return 8
        case .sectionTitle: return 12
        case .witnessLabel, .courtLabel: return 5
        case .counselLabel: return 3
        case .verse: return 4
        default: return 2
        }
    }

    #if canImport(UIKit)
    private func platformFont(for token: TypographyToken, scale: CGFloat) -> PlatformFont {
        let size = basePointSize(for: token.textStyle) * scale
        let weight: UIFont.Weight
        switch token.weight {
        case .regular: weight = .regular
        case .medium: weight = .medium
        case .semibold: weight = .semibold
        case .bold: weight = .bold
        case .black: weight = .black
        }
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let design: UIFontDescriptor.SystemDesign
        switch token.design {
        case .serif: design = .serif
        case .rounded: design = .rounded
        case .monospaced: design = .monospaced
        case .system: design = .default
        }
        if let descriptor = base.fontDescriptor.withDesign(design) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }
    #elseif canImport(AppKit)
    private func platformFont(for token: TypographyToken, scale: CGFloat) -> PlatformFont {
        let size = basePointSize(for: token.textStyle) * scale
        switch token.design {
        case .serif:
            let name: String
            switch token.weight {
            case .bold, .black, .semibold: name = "Times New Roman Bold"
            default: name = "Times New Roman"
            }
            return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size)
        case .monospaced:
            return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        case .rounded, .system:
            let weight: NSFont.Weight
            switch token.weight {
            case .regular: weight = .regular
            case .medium: weight = .medium
            case .semibold: weight = .semibold
            case .bold: weight = .bold
            case .black: weight = .black
            }
            return NSFont.systemFont(ofSize: size, weight: weight)
        }
    }
    #endif
}
