import Foundation
import CoreGraphics
import JJWWReaderCore
import JJWWTypography
import JJWWScrollReader

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
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
        let segments = makeSegments(
            units: units,
            rules: configuration.presentationRules
        )

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

        let result = PaginationResult(
            configuration: configuration,
            cacheKey: key,
            pages: pages
        )
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
        guard TypographyCatalog.profile(id: firstUnit.typographyProfile.id) != nil else {
            throw PaginationError.missingTypographyProfile(
                firstUnit.typographyProfile.id
            )
        }

        let composition = PageCompositionCatalog.profile(for: firstUnit)
        let source = try buildAttributedSource(
            units: units,
            textScale: configuration.textScale
        )

        #if canImport(UIKit) || canImport(AppKit)
        let textStorage = NSTextStorage(
            attributedString: source.attributedString
        )
        let layoutManager = NSLayoutManager()
        layoutManager.usesFontLeading = true
        textStorage.addLayoutManager(layoutManager)

        var pageCharacterRanges: [NSRange] = []
        var pageMargins: [PageMargins] = []
        var pageKinds: [PageCompositionKind] = []
        var coveredCharacters = 0
        var guardCount = 0

        while coveredCharacters < source.attributedString.length {
            guardCount += 1
            if guardCount > 10_000 {
                throw PaginationError.textKitProducedEmptyPage(segmentID)
            }

            let opening = pageCharacterRanges.isEmpty
            let kind = PageCompositionCatalog.kind(
                for: firstUnit,
                opening: opening
            )
            let margins = composition.margins(for: kind)
            let container = NSTextContainer(
                size: configuration.geometry.contentSize(using: margins)
            )
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

            pageCharacterRanges.append(characterRange)
            pageMargins.append(margins)
            pageKinds.append(kind)
            coveredCharacters = max(
                coveredCharacters,
                NSMaxRange(characterRange)
            )
        }

        var result: [PageSlice] = []
        for (localPageIndex, characterRange) in pageCharacterRanges.enumerated() {
            let fragments = fragments(
                for: characterRange,
                records: source.lineRecords
            )
            guard let firstFragment = fragments.first,
                  let lastFragment = fragments.last else {
                continue
            }

            let readingUnitIDs = fragments.reduce(into: [String]()) {
                ids,
                fragment in
                if !ids.contains(fragment.readingUnitID) {
                    ids.append(fragment.readingUnitID)
                }
            }
            let pageIndex = globalPageIndex + localPageIndex
            let firstUnitForPage = units.first(
                where: { $0.id == firstFragment.readingUnitID }
            ) ?? firstUnit
            let lastUnitForPage = units.first(
                where: { $0.id == lastFragment.readingUnitID }
            ) ?? firstUnit

            let startAnchor = ReadingAnchor(
                canonicalLayer0Version: firstUnitForPage
                    .canonicalAnchor
                    .canonicalLayer0Version,
                startLine: firstFragment.canonicalLine,
                endLine: firstFragment.canonicalLine
            )
            let endAnchor = ReadingAnchor(
                canonicalLayer0Version: lastUnitForPage
                    .canonicalAnchor
                    .canonicalLayer0Version,
                startLine: lastFragment.canonicalLine,
                endLine: lastFragment.canonicalLine
            )
            let startsAtUnitBeginning = units.contains { unit in
                unit.id == firstFragment.readingUnitID &&
                unit.canonicalAnchor.startLine ==
                    firstFragment.canonicalLine &&
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
                    beginsSectionTransition: startsAtUnitBeginning,
                    compositionKind: pageKinds[localPageIndex],
                    compositionProfileID: composition.id,
                    resolvedMargins: pageMargins[localPageIndex],
                    textScale: configuration.textScale,
                    pageWidth: configuration.geometry.width
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
        let layoutText: String
        let role: TypographyRole
        let textRange: NSRange
        let separatorLocation: Int?
        let separatorKind: PageTextSeparator
        let isOpeningHeader: Bool
        let isFirstOpeningHeader: Bool
        let isLastOpeningHeader: Bool
    }

    private struct AttributedSource {
        let attributedString: NSAttributedString
        let lineRecords: [LineRecord]
    }

    private func buildAttributedSource(
        units: [ReadingUnit],
        textScale: ReaderTextScale
    ) throws -> AttributedSource {
        let output = NSMutableAttributedString(string: "")
        var records: [LineRecord] = []

        let presentations:
            [(ReadingUnit, DocumentBlock, ReaderLinePresentation)] =
            units.flatMap { unit in
                unit.blocks.flatMap { block in
                    ReaderLineRoleResolver
                        .presentations(for: block, in: unit)
                        .map { (unit, block, $0) }
                }
            }

        let openingIndices = presentations.enumerated()
            .filter { $0.element.2.usesInkAwakening }
            .map(\.offset)
        let firstOpeningIndex = openingIndices.first
        let lastOpeningIndex = openingIndices.last

        for (index, item) in presentations.enumerated() {
            let (unit, block, presentation) = item
            guard let resolved = PageTypographyResolver.resolve(
                text: presentation.canonicalLine.text,
                canonicalLine: presentation.canonicalLine.number,
                role: presentation.role,
                unit: unit,
                textScale: textScale,
                isOpeningHeader: presentation.usesInkAwakening,
                isFirstOpeningHeader: index == firstOpeningIndex,
                isLastOpeningHeader: index == lastOpeningIndex
            ) else {
                throw PaginationError.missingTypographyProfile(
                    unit.typographyProfile.id
                )
            }

            let canonicalText = presentation.canonicalLine.text
            let layoutText = layoutTextPreservingCanonicalOffsets(
                canonical: canonicalText,
                proposedDisplay: resolved.displayText
            )
            let start = output.length

            #if canImport(UIKit) || canImport(AppKit)
            output.append(
                NSAttributedString(
                    string: layoutText,
                    attributes: resolved.attributedStringAttributes
                )
            )
            #else
            output.append(NSAttributedString(string: layoutText))
            #endif

            let textRange = NSRange(
                location: start,
                length: (canonicalText as NSString).length
            )

            var separatorLocation: Int?
            var separatorKind: PageTextSeparator = .none
            if index < presentations.count - 1 {
                separatorLocation = output.length
                let next = presentations[index + 1]
                separatorKind = next.0.id == unit.id
                    ? .lineBreak
                    : .readingUnitBreak

                #if canImport(UIKit) || canImport(AppKit)
                output.append(
                    NSAttributedString(
                        string: "\n",
                        attributes: resolved.attributedStringAttributes
                    )
                )
                #else
                output.append(NSAttributedString(string: "\n"))
                #endif
            }

            records.append(
                LineRecord(
                    readingUnitID: unit.id,
                    blockID: block.id,
                    canonicalLine: presentation.canonicalLine,
                    layoutText: layoutText,
                    role: presentation.role,
                    textRange: textRange,
                    separatorLocation: separatorLocation,
                    separatorKind: separatorKind,
                    isOpeningHeader: presentation.usesInkAwakening,
                    isFirstOpeningHeader: index == firstOpeningIndex,
                    isLastOpeningHeader: index == lastOpeningIndex
                )
            )
        }

        return AttributedSource(
            attributedString: output,
            lineRecords: records
        )
    }

    private func fragments(
        for pageRange: NSRange,
        records: [LineRecord]
    ) -> [PageTextFragment] {
        var result: [PageTextFragment] = []

        for record in records {
            let intersection = NSIntersectionRange(
                pageRange,
                record.textRange
            )
            let includesSeparator: Bool
            if let separatorLocation = record.separatorLocation {
                includesSeparator =
                    separatorLocation >= pageRange.location &&
                    separatorLocation < NSMaxRange(pageRange)
            } else {
                includesSeparator = false
            }

            guard intersection.length > 0 || includesSeparator else {
                continue
            }

            let localStart = max(
                0,
                intersection.location - record.textRange.location
            )
            let localEnd = localStart + intersection.length
            let canonicalText: String
            let displayText: String?

            if intersection.length > 0 {
                let range = NSRange(
                    location: localStart,
                    length: intersection.length
                )
                canonicalText = (record.canonicalLine.text as NSString)
                    .substring(with: range)
                let display = (record.layoutText as NSString)
                    .substring(with: range)
                displayText = display == canonicalText ? nil : display
            } else {
                canonicalText = ""
                displayText = nil
            }

            result.append(
                PageTextFragment(
                    id: "\(record.readingUnitID).\(record.blockID).\(record.canonicalLine.number).\(localStart)-\(localEnd).\(pageRange.location)",
                    readingUnitID: record.readingUnitID,
                    blockID: record.blockID,
                    canonicalLine: record.canonicalLine.number,
                    utf16Start: localStart,
                    utf16EndExclusive: localEnd,
                    text: canonicalText,
                    displayText: displayText,
                    role: record.role,
                    trailingSeparator: includesSeparator
                        ? record.separatorKind
                        : .none,
                    isOpeningHeader: record.isOpeningHeader,
                    isFirstOpeningHeader: record.isFirstOpeningHeader,
                    isLastOpeningHeader: record.isLastOpeningHeader
                )
            )
        }

        return result
    }

    private func layoutTextPreservingCanonicalOffsets(
        canonical: String,
        proposedDisplay: String
    ) -> String {
        guard (canonical as NSString).length ==
                (proposedDisplay as NSString).length else {
            return canonical
        }
        return proposedDisplay
    }
}
