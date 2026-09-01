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

    public init(
        id: String,
        canonicalLine: CanonicalLine,
        role: TypographyRole,
        usesInkAwakening: Bool
    ) {
        self.id = id
        self.canonicalLine = canonicalLine
        self.role = role
        self.usesInkAwakening = usesInkAwakening
    }
}

public enum ReaderLineRoleResolver {
    public static func presentations(
        for block: DocumentBlock,
        in unit: ReadingUnit
    ) -> [ReaderLinePresentation] {
        let nonEmptyIndices = block.lines.enumerated()
            .filter { !$0.element.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map(\.offset)
        let openingIndices = Set(nonEmptyIndices.prefix(3))

        return block.lines.enumerated().map { index, line in
            let role = role(for: line.text, index: index, openingIndices: openingIndices, unit: unit)
            let usesInk = openingIndices.contains(index) && (
                role == .dateHeading || role == .sourceHeader || role == .sectionTitle
            )
            return ReaderLinePresentation(
                id: "\(block.id).line.\(line.number)",
                canonicalLine: line,
                role: role,
                usesInkAwakening: usesInk
            )
        }
    }

    private static func role(
        for text: String,
        index: Int,
        openingIndices: Set<Int>,
        unit: ReadingUnit
    ) -> TypographyRole {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .body }

        if unit.kind == .cover { return .editorialCutPaper }

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
