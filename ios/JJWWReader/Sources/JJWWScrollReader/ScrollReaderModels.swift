import Foundation
import SwiftUI
import Combine
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography

public enum ReaderMaterialSetting: String, CaseIterable, Codable, Sendable {
    case full
    case reduced
    case clean

    public var materialState: MaterialState {
        switch self {
        case .full: return .full
        case .reduced: return .reduced
        case .clean: return .clean
        }
    }
}

public enum ReaderTextScale: String, CaseIterable, Codable, Sendable {
    case standard
    case large
    case accessibility

    public var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .standard: return .large
        case .large: return .xxLarge
        case .accessibility: return .accessibility2
        }
    }
}

public enum ReaderDisplayMode: String, CaseIterable, Codable, Sendable {
    case scroll
    case pages
}

public struct ReaderLinePresentation: Equatable, Sendable, Identifiable {
    public let id: String
    public let canonicalLine: CanonicalLine
    public let role: TypographyRole
    public let usesInkAwakening: Bool
    public let semanticSpanIDs: [String]
    public let semanticTypes: [String]
    public let sourceOccurrenceIDs: [String]
    public let sourceContextIDs: [String]

    public init(
        id: String,
        canonicalLine: CanonicalLine,
        role: TypographyRole,
        usesInkAwakening: Bool,
        semanticSpanIDs: [String] = [],
        semanticTypes: [String] = [],
        sourceOccurrenceIDs: [String] = [],
        sourceContextIDs: [String] = []
    ) {
        self.id = id
        self.canonicalLine = canonicalLine
        self.role = role
        self.usesInkAwakening = usesInkAwakening
        self.semanticSpanIDs = semanticSpanIDs
        self.semanticTypes = semanticTypes
        self.sourceOccurrenceIDs = sourceOccurrenceIDs
        self.sourceContextIDs = sourceContextIDs
    }
}

public enum ReaderLineRoleResolver {
    private static let documentOpeningTypes: Set<String> = [
        "front_matter_title_block",
        "section_item",
        "confession_document",
        "trial_source_section",
        "historical_work_section",
        "official_examination_document",
        "newspaper_item",
        "periodical_item",
        "broadside_document",
        "poem_document",
        "letter_document",
        "advertisement_document",
        "will_document",
        "genealogical_section",
        "legal_notice_document",
        "testimony_document",
        "farewell_document",
        "appendix_section",
        "appendix_people_index",
        "appendix_timeline",
        "bibliography_section",
        "acknowledgments_section",
        "copyright_section",
        "back_matter_title",
        "request_document",
        "registration_document",
        "museum_card"
    ]

    public static func presentations(
        for block: DocumentBlock,
        in unit: ReadingUnit
    ) -> [ReaderLinePresentation] {
        let nonEmptyIndices = block.lines.enumerated()
            .filter { !$0.element.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map(\.offset)
        let openingIndices = Set(nonEmptyIndices.prefix(3))
        let hasLayer1Semantics = block.semantics != nil

        return block.lines.enumerated().map { index, line in
            let spans = block.semanticSpans.filter { $0.canonicalAnchor.contains(line: line.number) }
            let occurrences = block.sourceOccurrences.filter { $0.applies(to: line.number) }
            let contexts = block.sourceContexts.filter { $0.canonicalAnchor.contains(line: line.number) }
            let resolvedRole = role(
                for: line,
                index: index,
                openingIndices: openingIndices,
                unit: unit,
                spans: spans,
                occurrences: occurrences,
                contexts: contexts,
                hasLayer1Semantics: hasLayer1Semantics
            )
            let usesInk = openingIndices.contains(index) && (
                resolvedRole == .dateHeading ||
                resolvedRole == .sourceHeader ||
                resolvedRole == .sectionTitle
            )
            return ReaderLinePresentation(
                id: "\(block.id).line.\(line.number)",
                canonicalLine: line,
                role: resolvedRole,
                usesInkAwakening: usesInk,
                semanticSpanIDs: spans.map(\.id),
                semanticTypes: Array(Set(spans.map(\.type))).sorted(),
                sourceOccurrenceIDs: occurrences.map(\.id),
                sourceContextIDs: contexts.map(\.id)
            )
        }
    }

    private static func role(
        for line: CanonicalLine,
        index: Int,
        openingIndices: Set<Int>,
        unit: ReadingUnit,
        spans: [DocumentSemanticSpan],
        occurrences: [DocumentSourceOccurrence],
        contexts: [DocumentSourceContext],
        hasLayer1Semantics: Bool
    ) -> TypographyRole {
        let trimmed = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .body }

        if unit.kind == .cover { return .editorialCutPaper }

        if hasLayer1Semantics {
            if isSemanticDate(line: line, spans: spans) {
                return .dateHeading
            }
            if isDirectSourceAttribution(line: line, occurrences: occurrences) {
                return .sourceHeader
            }
            if openingIndices.contains(index), isSemanticOpening(line: line, spans: spans) {
                return .sectionTitle
            }
            if isSemanticProceduralLabel(line: line, spans: spans) {
                if looksLikeCourtLabel(trimmed) { return .courtLabel }
                return .counselLabel
            }
            if isSemanticWitnessLabel(line: line, spans: spans) {
                return .witnessLabel
            }

            let sourceTypes = Set(
                occurrences.map(\.source.sourceType) + contexts.map(\.source.sourceType)
            )
            if sourceTypes.contains("confession_pamphlet") {
                return .firstPersonBody
            }
            if unit.sourcePresentation?.sourceKind == .literaryArtifact {
                return .verse
            }
            return .body
        }

        if openingIndices.contains(index) {
            if looksLikeDate(trimmed) { return .dateHeading }
            if looksLikeSourceHeader(trimmed, unit: unit) { return .sourceHeader }
            if looksLikeSectionTitle(trimmed) { return .sectionTitle }
        }

        switch unit.sourcePresentation?.sourceKind {
        case .confessionPamphlet:
            return .firstPersonBody
        case .trialPamphlet:
            if looksLikeCourtLabel(trimmed) { return .courtLabel }
            if looksLikeCounselLabel(trimmed) { return .counselLabel }
            if looksLikeWitnessLabel(trimmed) { return .witnessLabel }
            return .body
        case .literaryArtifact:
            return .verse
        default:
            return .body
        }
    }

    private static func isSemanticDate(
        line: CanonicalLine,
        spans: [DocumentSemanticSpan]
    ) -> Bool {
        spans.contains {
            $0.type == "dated_item" && $0.canonicalAnchor.startLine == line.number
        }
    }

    private static func isDirectSourceAttribution(
        line: CanonicalLine,
        occurrences: [DocumentSourceOccurrence]
    ) -> Bool {
        occurrences.contains {
            $0.role == "direct_attribution" && $0.attributionAnchor.contains(line: line.number)
        }
    }

    private static func isSemanticOpening(
        line: CanonicalLine,
        spans: [DocumentSemanticSpan]
    ) -> Bool {
        spans.contains { span in
            span.canonicalAnchor.startLine == line.number && (
                documentOpeningTypes.contains(span.type) || span.type == "uppercase_display_line"
            )
        }
    }

    private static func isSemanticProceduralLabel(
        line: CanonicalLine,
        spans: [DocumentSemanticSpan]
    ) -> Bool {
        spans.contains {
            $0.type == "procedural_or_speaker_label" &&
            $0.canonicalAnchor.startLine == line.number &&
            $0.canonicalAnchor.endLine == line.number &&
            line.text.count < 160
        }
    }

    private static func isSemanticWitnessLabel(
        line: CanonicalLine,
        spans: [DocumentSemanticSpan]
    ) -> Bool {
        guard line.text.count < 160 else { return false }
        let lower = line.text.lowercased()
        let labelLike = lower.contains("sworn") || lower.contains("called") || lower.contains("recalled")
        return labelLike && spans.contains {
            $0.type == "witness_testimony_segment" && $0.canonicalAnchor.startLine == line.number
        }
    }

    private static func looksLikeDate(_ text: String) -> Bool {
        let lower = text.lowercased()
        let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        let months = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"]
        return text.count < 80 && (
            weekdays.contains(where: lower.contains) ||
            (months.contains(where: lower.contains) && lower.contains("1827"))
        )
    }

    private static func looksLikeSourceHeader(_ text: String, unit: ReadingUnit) -> Bool {
        guard text.count < 120 else { return false }
        let lower = text.lowercased()
        if let title = unit.sourcePresentation?.displayTitle.lowercased() {
            let significant = title
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.count >= 4 }
            if significant.prefix(2).allSatisfy({ lower.contains($0) }) {
                return true
            }
        }
        let sourceWords = ["argus", "advertiser", "gazette", "journal", "sentinel"]
        return sourceWords.contains(where: lower.contains)
    }

    private static func looksLikeSectionTitle(_ text: String) -> Bool {
        guard text.count <= 90 else { return false }
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard !letters.isEmpty else { return false }
        let uppercaseCount = letters.filter { CharacterSet.uppercaseLetters.contains($0) }.count
        let uppercaseRatio = Double(uppercaseCount) / Double(letters.count)
        return uppercaseRatio > 0.60 || text.hasSuffix(":") || text.lowercased().contains("confession") || text.lowercased().contains("trial") || text.lowercased().contains("farewell")
    }

    private static func looksLikeWitnessLabel(_ text: String) -> Bool {
        let lower = text.lowercased()
        return (lower.contains("sworn") || lower.contains("called and sworn")) && text.count < 120
    }

    private static func looksLikeCounselLabel(_ text: String) -> Bool {
        let lower = text.lowercased()
        return text.count < 120 && (
            lower.hasPrefix("by oakley") ||
            lower.hasPrefix("by foot") ||
            lower.hasPrefix("by the district attorney") ||
            lower.hasPrefix("mr. oakley") ||
            lower.hasPrefix("mr. foot")
        )
    }

    private static func looksLikeCourtLabel(_ text: String) -> Bool {
        let lower = text.lowercased()
        return text.count < 160 && (
            lower.hasPrefix("the court") || lower.hasPrefix("court.") || lower.hasPrefix("court—")
        )
    }
}

public enum ReaderInkProfileResolver {
    public static func profile(for unit: ReadingUnit) -> InkAwakeningProfile? {
        switch unit.materialProfile.id {
        case MaterialProfile.argus1827.id:
            return InkAwakeningCatalog.argus
        case MaterialProfile.dailyAdvertiser1827.id:
            return InkAwakeningCatalog.dailyAdvertiser
        case MaterialProfile.confessionPamphlet1827.id:
            return InkAwakeningCatalog.confession
        case MaterialProfile.trialRecord1827.id:
            return InkAwakeningCatalog.trial
        case MaterialProfile.farewell1827.id:
            return InkAwakeningCatalog.farewell
        default:
            return nil
        }
    }
}

public protocol ReaderLocationPersistence: AnyObject {
    func load(editionID: String) -> ReaderLocation?
    func save(_ location: ReaderLocation, editionID: String)
}

public final class UserDefaultsReaderLocationPersistence: ReaderLocationPersistence {
    private let defaults: UserDefaults
    private let keyPrefix: String

    public init(defaults: UserDefaults = .standard, keyPrefix: String = "jjww.reader.location") {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    public func load(editionID: String) -> ReaderLocation? {
        guard let data = defaults.data(forKey: "\(keyPrefix).\(editionID)") else { return nil }
        return try? JSONDecoder().decode(ReaderLocation.self, from: data)
    }

    public func save(_ location: ReaderLocation, editionID: String) {
        guard let data = try? JSONEncoder().encode(location) else { return }
        defaults.set(data, forKey: "\(keyPrefix).\(editionID)")
    }
}

public final class MemoryReaderLocationPersistence: ReaderLocationPersistence {
    public private(set) var locations: [String: ReaderLocation] = [:]

    public init() {}

    public func load(editionID: String) -> ReaderLocation? {
        locations[editionID]
    }

    public func save(_ location: ReaderLocation, editionID: String) {
        locations[editionID] = location
    }
}

@MainActor
public final class ScrollReaderSession: ObservableObject {
    public let edition: Edition

    @Published public var materialSetting: ReaderMaterialSetting
    @Published public var textScale: ReaderTextScale
    @Published public private(set) var displayMode: ReaderDisplayMode
    @Published public private(set) var location: ReaderLocation
    @Published public private(set) var navigationRevision: Int = 0

    private let persistence: ReaderLocationPersistence
    private var pendingScrollNavigationUnitID: String?

    public init(
        edition: Edition,
        persistence: ReaderLocationPersistence = UserDefaultsReaderLocationPersistence(),
        materialSetting: ReaderMaterialSetting = .full,
        textScale: ReaderTextScale = .standard
    ) {
        self.edition = edition
        self.persistence = persistence
        self.materialSetting = materialSetting
        self.textScale = textScale
        self.displayMode = .scroll

        let fallback = ScrollReaderSession.firstLocation(in: edition)
        if let restored = persistence.load(editionID: edition.id),
           ScrollReaderSession.contains(restored, in: edition) {
            self.location = restored
        } else {
            self.location = fallback
        }
    }

    public func focus(unit: ReadingUnit, canonicalLine: Int? = nil) {
        if let pendingUnitID = pendingScrollNavigationUnitID {
            guard unit.id == pendingUnitID else { return }
            pendingScrollNavigationUnitID = nil
        }

        if canonicalLine == nil, location.readingUnitID == unit.id {
            return
        }

        guard let block = unit.blocks.first(where: { block in
            guard let canonicalLine else { return true }
            return block.canonicalAnchor.contains(line: canonicalLine)
        }) ?? unit.blocks.first else { return }

        let line = canonicalLine ?? block.canonicalAnchor.startLine
        guard block.canonicalAnchor.contains(line: line) else { return }

        let next = ReaderLocation(
            readingUnitID: unit.id,
            blockID: block.id,
            canonicalLine: line,
            utf16OffsetInLine: 0
        )
        setLocation(next, requestScrollNavigation: false)
    }

    public func move(to next: ReaderLocation, requestScrollNavigation: Bool) {
        guard ScrollReaderSession.contains(next, in: edition) else { return }
        setLocation(next, requestScrollNavigation: requestScrollNavigation)
    }

    public func requestPagesMode() {
        pendingScrollNavigationUnitID = nil
        displayMode = .pages
    }

    public func requestScrollMode() {
        displayMode = .scroll
    }

    public var progress: Double {
        let orderedLines = edition.orderedReadingUnits
            .flatMap(\.blocks)
            .flatMap(\.lines)
            .map(\.number)
        guard !orderedLines.isEmpty,
              let index = orderedLines.firstIndex(of: location.canonicalLine) else {
            return 0
        }
        if orderedLines.count == 1 { return 1 }
        return Double(index) / Double(orderedLines.count - 1)
    }

    public func changingMaterial(to setting: ReaderMaterialSetting) {
        materialSetting = setting
    }

    public func changingTextScale(to scale: ReaderTextScale) {
        textScale = scale
    }

    private func setLocation(_ next: ReaderLocation, requestScrollNavigation: Bool) {
        if requestScrollNavigation, displayMode == .pages {
            pendingScrollNavigationUnitID = next.readingUnitID
        }

        let changed = next != location
        if changed {
            location = next
            persistence.save(next, editionID: edition.id)
        }
        if requestScrollNavigation {
            navigationRevision &+= 1
        }
    }

    private static func firstLocation(in edition: Edition) -> ReaderLocation {
        guard let unit = edition.orderedReadingUnits.first,
              let block = unit.blocks.first else {
            return ReaderLocation(readingUnitID: "", blockID: "", canonicalLine: 0)
        }
        return ReaderLocation(
            readingUnitID: unit.id,
            blockID: block.id,
            canonicalLine: block.canonicalAnchor.startLine
        )
    }

    public static func contains(_ location: ReaderLocation, in edition: Edition) -> Bool {
        guard let unit = edition.readingUnit(id: location.readingUnitID),
              let block = unit.blocks.first(where: { $0.id == location.blockID }) else {
            return false
        }
        return block.canonicalAnchor.contains(line: location.canonicalLine)
    }
}
