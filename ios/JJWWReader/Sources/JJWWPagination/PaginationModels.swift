import Foundation
import CoreGraphics
import JJWWReaderCore
import JJWWTypography
import JJWWScrollReader

public struct PageMargins: Codable, Equatable, Hashable, Sendable {
    public let top: Double
    public let leading: Double
    public let bottom: Double
    public let trailing: Double

    public init(top: Double, leading: Double, bottom: Double, trailing: Double) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    public static let phonePortrait = PageMargins(top: 54, leading: 34, bottom: 56, trailing: 34)
}

public struct PageGeometry: Codable, Equatable, Hashable, Sendable {
    public let width: Double
    public let height: Double
    public let margins: PageMargins

    public init(width: Double, height: Double, margins: PageMargins) {
        self.width = width
        self.height = height
        self.margins = margins
    }

    public static let phonePortrait = PageGeometry(width: 390, height: 844, margins: .phonePortrait)

    public var contentWidth: Double {
        max(1, width - margins.leading - margins.trailing)
    }

    public var contentHeight: Double {
        max(1, height - margins.top - margins.bottom)
    }

    public var contentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    public func contentSize(using margins: PageMargins) -> CGSize {
        CGSize(
            width: max(1, width - margins.leading - margins.trailing),
            height: max(1, height - margins.top - margins.bottom)
        )
    }
}

public struct PaginationPresentationRules: Codable, Equatable, Hashable, Sendable {
    public let version: String
    public let breakAtMaterialChange: Bool
    public let breakAtTypographyChange: Bool
    public let breakAtSourceWorkChange: Bool

    public init(
        version: String,
        breakAtMaterialChange: Bool,
        breakAtTypographyChange: Bool,
        breakAtSourceWorkChange: Bool
    ) {
        self.version = version
        self.breakAtMaterialChange = breakAtMaterialChange
        self.breakAtTypographyChange = breakAtTypographyChange
        self.breakAtSourceWorkChange = breakAtSourceWorkChange
    }

    public static let prototype = PaginationPresentationRules(
        version: "stage5-prototype-v0.1",
        breakAtMaterialChange: true,
        breakAtTypographyChange: true,
        breakAtSourceWorkChange: true
    )

    public func requiresNewLeaf(between lhs: ReadingUnit, and rhs: ReadingUnit) -> Bool {
        if breakAtMaterialChange && lhs.materialProfile != rhs.materialProfile { return true }
        if breakAtTypographyChange && lhs.typographyProfile != rhs.typographyProfile { return true }
        if breakAtSourceWorkChange && lhs.sourcePresentation?.workID != rhs.sourcePresentation?.workID { return true }
        return false
    }
}

public struct PaginationConfiguration: Codable, Equatable, Sendable {
    public let geometry: PageGeometry
    public let textScale: ReaderTextScale
    public let typographyProfileVersion: String
    public let marginProfileVersion: String
    public let pageCompositionProfileVersion: String
    public let presentationRules: PaginationPresentationRules
    public let includeCoverUnit: Bool

    public init(
        geometry: PageGeometry = .phonePortrait,
        textScale: ReaderTextScale = .standard,
        typographyProfileVersion: String = "typography-stage3-v0.1",
        marginProfileVersion: String = "page-margins-stage5-v0.1",
        pageCompositionProfileVersion: String = "page-composition-stage5.5-v0.1",
        presentationRules: PaginationPresentationRules = .prototype,
        includeCoverUnit: Bool = false
    ) {
        self.geometry = geometry
        self.textScale = textScale
        self.typographyProfileVersion = typographyProfileVersion
        self.marginProfileVersion = marginProfileVersion
        self.pageCompositionProfileVersion = pageCompositionProfileVersion
        self.presentationRules = presentationRules
        self.includeCoverUnit = includeCoverUnit
    }

    public func cacheKey(for edition: Edition) -> PaginationCacheKey {
        PaginationCacheKey(
            pageWidth: geometry.width,
            pageHeight: geometry.height,
            marginTop: geometry.margins.top,
            marginLeading: geometry.margins.leading,
            marginBottom: geometry.margins.bottom,
            marginTrailing: geometry.margins.trailing,
            textScale: textScale.rawValue,
            typographyProfileVersion: typographyProfileVersion,
            marginProfileVersion: marginProfileVersion,
            pageCompositionProfileVersion: pageCompositionProfileVersion,
            presentationRulesVersion: presentationRules.version,
            editionVersion: edition.version,
            canonicalLineSequenceSHA256: edition.canonicalLineSequenceSHA256,
            includeCoverUnit: includeCoverUnit
        )
    }
}

public struct PaginationCacheKey: Codable, Equatable, Hashable, Sendable {
    public let pageWidth: Double
    public let pageHeight: Double
    public let marginTop: Double
    public let marginLeading: Double
    public let marginBottom: Double
    public let marginTrailing: Double
    public let textScale: String
    public let typographyProfileVersion: String
    public let marginProfileVersion: String
    public let pageCompositionProfileVersion: String
    public let presentationRulesVersion: String
    public let editionVersion: String
    public let canonicalLineSequenceSHA256: String
    public let includeCoverUnit: Bool
}

public enum PageSide: String, Codable, Equatable, Sendable {
    case recto
    case verso
}

public enum PageTextSeparator: String, Codable, Equatable, Sendable {
    case none
    case lineBreak
    case readingUnitBreak
}

public struct PageTextRange: Codable, Equatable, Hashable, Sendable {
    public let location: Int
    public let length: Int

    public init(location: Int, length: Int) {
        self.location = location
        self.length = length
    }

    public var upperBound: Int { location + length }
}

public struct PageTextFragment: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let readingUnitID: String
    public let blockID: String
    public let canonicalLine: Int
    public let utf16Start: Int
    public let utf16EndExclusive: Int
    public let text: String
    public let role: TypographyRole
    public let trailingSeparator: PageTextSeparator

    public init(
        id: String,
        readingUnitID: String,
        blockID: String,
        canonicalLine: Int,
        utf16Start: Int,
        utf16EndExclusive: Int,
        text: String,
        role: TypographyRole,
        trailingSeparator: PageTextSeparator
    ) {
        self.id = id
        self.readingUnitID = readingUnitID
        self.blockID = blockID
        self.canonicalLine = canonicalLine
        self.utf16Start = utf16Start
        self.utf16EndExclusive = utf16EndExclusive
        self.text = text
        self.role = role
        self.trailingSeparator = trailingSeparator
    }

    public var exactLayoutText: String {
        text + (trailingSeparator == .none ? "" : "\n")
    }

    public var exactCanonicalUnitText: String {
        text + (trailingSeparator == .lineBreak ? "\n" : "")
    }
}

public struct PageSlice: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let pageIndex: Int
    public let layoutSegmentID: String
    public let segmentTextRange: PageTextRange
    public let readingUnitIDs: [String]
    public let startAnchor: ReadingAnchor
    public let endAnchor: ReadingAnchor
    public let startLocation: ReaderLocation
    public let endLocationExclusive: ReaderLocation
    public let fragments: [PageTextFragment]
    public let materialProfile: MaterialProfile
    public let side: PageSide
    public let beginsSectionTransition: Bool
    public let compositionKind: PageCompositionKind
    public let compositionProfileID: String
    public let resolvedMargins: PageMargins

    public init(
        id: String,
        pageIndex: Int,
        layoutSegmentID: String,
        segmentTextRange: PageTextRange,
        readingUnitIDs: [String],
        startAnchor: ReadingAnchor,
        endAnchor: ReadingAnchor,
        startLocation: ReaderLocation,
        endLocationExclusive: ReaderLocation,
        fragments: [PageTextFragment],
        materialProfile: MaterialProfile,
        side: PageSide,
        beginsSectionTransition: Bool,
        compositionKind: PageCompositionKind,
        compositionProfileID: String,
        resolvedMargins: PageMargins
    ) {
        self.id = id
        self.pageIndex = pageIndex
        self.layoutSegmentID = layoutSegmentID
        self.segmentTextRange = segmentTextRange
        self.readingUnitIDs = readingUnitIDs
        self.startAnchor = startAnchor
        self.endAnchor = endAnchor
        self.startLocation = startLocation
        self.endLocationExclusive = endLocationExclusive
        self.fragments = fragments
        self.materialProfile = materialProfile
        self.side = side
        self.beginsSectionTransition = beginsSectionTransition
        self.compositionKind = compositionKind
        self.compositionProfileID = compositionProfileID
        self.resolvedMargins = resolvedMargins
    }

    public var pageNumber: Int { pageIndex + 1 }

    public var reconstructedLayoutText: String {
        fragments.map(\.exactLayoutText).joined()
    }

    public func contains(_ location: ReaderLocation) -> Bool {
        guard readingUnitIDs.contains(location.readingUnitID) else { return false }
        return fragments.contains { fragment in
            guard fragment.readingUnitID == location.readingUnitID,
                  fragment.blockID == location.blockID,
                  fragment.canonicalLine == location.canonicalLine else {
                return false
            }
            if fragment.utf16Start == fragment.utf16EndExclusive {
                return location.utf16OffsetInLine == fragment.utf16Start && fragment.trailingSeparator != .none
            }
            if location.utf16OffsetInLine >= fragment.utf16Start && location.utf16OffsetInLine < fragment.utf16EndExclusive {
                return true
            }
            return location.utf16OffsetInLine == fragment.utf16EndExclusive && fragment.trailingSeparator != .none
        }
    }
}

public struct PaginationResult: Codable, Equatable, Sendable {
    public let configuration: PaginationConfiguration
    public let cacheKey: PaginationCacheKey
    public let pages: [PageSlice]

    public init(configuration: PaginationConfiguration, cacheKey: PaginationCacheKey, pages: [PageSlice]) {
        self.configuration = configuration
        self.cacheKey = cacheKey
        self.pages = pages
    }

    public func page(containing location: ReaderLocation) -> PageSlice? {
        pages.first { $0.contains(location) }
    }

    public func pages(representing readingUnitID: String) -> [PageSlice] {
        pages.filter { $0.readingUnitIDs.contains(readingUnitID) }
    }

    public func reconstructedCanonicalText(for readingUnitID: String) -> String {
        pages
            .flatMap(\.fragments)
            .filter { $0.readingUnitID == readingUnitID }
            .map(\.exactCanonicalUnitText)
            .joined()
    }
}

@MainActor
public final class PaginationCache {
    private var storage: [PaginationCacheKey: PaginationResult] = [:]
    private var insertionOrder: [PaginationCacheKey] = []
    public let capacity: Int

    public init(capacity: Int = 6) {
        self.capacity = max(1, capacity)
    }

    public func value(for key: PaginationCacheKey) -> PaginationResult? {
        storage[key]
    }

    public func store(_ result: PaginationResult) {
        let key = result.cacheKey
        if storage[key] == nil {
            insertionOrder.append(key)
        }
        storage[key] = result
        while insertionOrder.count > capacity {
            let evicted = insertionOrder.removeFirst()
            storage.removeValue(forKey: evicted)
        }
    }

    public func removeAll() {
        storage.removeAll()
        insertionOrder.removeAll()
    }

    public var count: Int { storage.count }
}
