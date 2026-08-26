import Foundation

public struct Edition: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let version: String
    public let canonicalLayer0Version: String
    public let canonicalLineSequenceSHA256: String
    public let readingUnits: [ReadingUnit]

    public init(
        id: String,
        title: String,
        version: String,
        canonicalLayer0Version: String,
        canonicalLineSequenceSHA256: String,
        readingUnits: [ReadingUnit]
    ) {
        self.id = id
        self.title = title
        self.version = version
        self.canonicalLayer0Version = canonicalLayer0Version
        self.canonicalLineSequenceSHA256 = canonicalLineSequenceSHA256
        self.readingUnits = readingUnits
    }

    public var orderedReadingUnits: [ReadingUnit] {
        readingUnits.sorted { lhs, rhs in
            if lhs.sequence == rhs.sequence {
                return lhs.id < rhs.id
            }
            return lhs.sequence < rhs.sequence
        }
    }

    public func readingUnit(id: String) -> ReadingUnit? {
        readingUnits.first { $0.id == id }
    }

    public func readingUnit(sequence: Int) -> ReadingUnit? {
        readingUnits.first { $0.sequence == sequence }
    }

    public func plainText(includeCover: Bool = true) -> String {
        orderedReadingUnits
            .filter { includeCover || $0.kind != .cover }
            .flatMap(\.blocks)
            .flatMap(\.lines)
            .map(\.text)
            .joined(separator: "\n")
    }
}

public struct ReadingUnit: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let sequence: Int
    public let kind: ReadingUnitKind
    public let canonicalAnchor: ReadingAnchor
    public let sourcePresentation: SourcePresentation?
    public let typographyProfile: TypographyProfile
    public let materialProfile: MaterialProfile
    public let blocks: [DocumentBlock]

    public init(
        id: String,
        sequence: Int,
        kind: ReadingUnitKind,
        canonicalAnchor: ReadingAnchor,
        sourcePresentation: SourcePresentation?,
        typographyProfile: TypographyProfile,
        materialProfile: MaterialProfile,
        blocks: [DocumentBlock]
    ) {
        self.id = id
        self.sequence = sequence
        self.kind = kind
        self.canonicalAnchor = canonicalAnchor
        self.sourcePresentation = sourcePresentation
        self.typographyProfile = typographyProfile
        self.materialProfile = materialProfile
        self.blocks = blocks
    }

    public var canonicalText: String {
        blocks
            .flatMap(\.lines)
            .map(\.text)
            .joined(separator: "\n")
    }
}

public enum ReadingUnitKind: String, Codable, Equatable, Sendable {
    case cover
    case section
}

public struct DocumentBlock: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let kind: DocumentBlockKind
    public let canonicalAnchor: ReadingAnchor
    public let sourcePassageID: String?
    public let lines: [CanonicalLine]

    public init(
        id: String,
        kind: DocumentBlockKind,
        canonicalAnchor: ReadingAnchor,
        sourcePassageID: String?,
        lines: [CanonicalLine]
    ) {
        self.id = id
        self.kind = kind
        self.canonicalAnchor = canonicalAnchor
        self.sourcePassageID = sourcePassageID
        self.lines = lines
    }
}

public enum DocumentBlockKind: String, Codable, Equatable, Sendable {
    case frontMatter
    case sourceText
}

public struct CanonicalLine: Codable, Equatable, Sendable {
    public let number: Int
    public let text: String

    public init(number: Int, text: String) {
        self.number = number
        self.text = text
    }
}

public struct SourcePresentation: Codable, Equatable, Sendable {
    public let workID: String
    public let passageIDs: [String]
    public let displayTitle: String
    public let sourceKind: SourceKind

    public init(
        workID: String,
        passageIDs: [String],
        displayTitle: String,
        sourceKind: SourceKind
    ) {
        self.workID = workID
        self.passageIDs = passageIDs
        self.displayTitle = displayTitle
        self.sourceKind = sourceKind
    }
}

public enum SourceKind: String, Codable, Equatable, Sendable {
    case periodical
    case confessionPamphlet
    case trialPamphlet
    case literaryArtifact
}

public struct TypographyProfile: Codable, Equatable, Hashable, Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }

    public static let jjwwEditorial = TypographyProfile(id: "jjwwEditorial")
    public static let newspaper1827 = TypographyProfile(id: "newspaper1827")
    public static let confessionPamphlet1827 = TypographyProfile(id: "confessionPamphlet1827")
    public static let trialRecord1827 = TypographyProfile(id: "trialRecord1827")
    public static let farewell1827 = TypographyProfile(id: "farewell1827")
}

public struct MaterialProfile: Codable, Equatable, Hashable, Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }

    public static let jjwwEditorial = MaterialProfile(id: "jjwwEditorial")
    public static let argus1827 = MaterialProfile(id: "argus1827")
    public static let dailyAdvertiser1827 = MaterialProfile(id: "dailyAdvertiser1827")
    public static let confessionPamphlet1827 = MaterialProfile(id: "confessionPamphlet1827")
    public static let trialRecord1827 = MaterialProfile(id: "trialRecord1827")
    public static let farewell1827 = MaterialProfile(id: "farewell1827")
}

public struct ReadingAnchor: Codable, Equatable, Hashable, Sendable {
    public let canonicalLayer0Version: String
    public let startLine: Int
    public let endLine: Int

    public init(canonicalLayer0Version: String, startLine: Int, endLine: Int) {
        self.canonicalLayer0Version = canonicalLayer0Version
        self.startLine = startLine
        self.endLine = endLine
    }

    public func contains(line: Int) -> Bool {
        startLine...endLine ~= line
    }
}

public struct ReaderLocation: Codable, Equatable, Hashable, Sendable {
    public let readingUnitID: String
    public let blockID: String
    public let canonicalLine: Int
    public let utf16OffsetInLine: Int

    public init(
        readingUnitID: String,
        blockID: String,
        canonicalLine: Int,
        utf16OffsetInLine: Int = 0
    ) {
        self.readingUnitID = readingUnitID
        self.blockID = blockID
        self.canonicalLine = canonicalLine
        self.utf16OffsetInLine = utf16OffsetInLine
    }
}
