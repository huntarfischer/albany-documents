import Foundation

public struct CanonicalOwnershipContainer: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let layer0BlockID: String
    public let layer0BlockType: String
    public let labelAsWritten: String
    public let canonicalAnchor: ReadingAnchor
    public let lines: [CanonicalLine]

    public init(
        id: String,
        layer0BlockID: String,
        layer0BlockType: String,
        labelAsWritten: String,
        canonicalAnchor: ReadingAnchor,
        lines: [CanonicalLine]
    ) {
        self.id = id
        self.layer0BlockID = layer0BlockID
        self.layer0BlockType = layer0BlockType
        self.labelAsWritten = labelAsWritten
        self.canonicalAnchor = canonicalAnchor
        self.lines = lines
    }

    public var canonicalText: String {
        lines.map(\.text).joined(separator: "\n")
    }
}

public struct Stage8CanonicalOwnershipBook: Codable, Equatable, Sendable {
    public let canonicalLayer0Version: String
    public let canonicalLineSequenceSHA256: String
    public let containers: [CanonicalOwnershipContainer]

    public init(
        canonicalLayer0Version: String,
        canonicalLineSequenceSHA256: String,
        containers: [CanonicalOwnershipContainer]
    ) {
        self.canonicalLayer0Version = canonicalLayer0Version
        self.canonicalLineSequenceSHA256 = canonicalLineSequenceSHA256
        self.containers = containers
    }

    public var lines: [CanonicalLine] {
        containers.flatMap(\.lines)
    }

    public func plainText() -> String {
        lines.map(\.text).joined(separator: "\n")
    }

    public func container(id: String) -> CanonicalOwnershipContainer? {
        containers.first { $0.id == id }
    }

    public func container(containing canonicalLine: Int) -> CanonicalOwnershipContainer? {
        containers.first { $0.canonicalAnchor.contains(line: canonicalLine) }
    }
}

public enum Stage8CanonicalOwnershipError: Error, Equatable, CustomStringConvertible {
    case canonicalFormatMismatch(expected: String, actual: String)
    case canonicalVersionMismatch(expected: String, actual: String)
    case canonicalLineCountMismatch(expected: Int, actual: Int)
    case canonicalSHAMismatch(expected: String, actual: String)
    case canonicalBlockCountMismatch(expected: Int, actual: Int)
    case emptyCanonicalBlock(String)

    public var description: String {
        switch self {
        case let .canonicalFormatMismatch(expected, actual):
            return "Canonical format mismatch. Expected \(expected), got \(actual)."
        case let .canonicalVersionMismatch(expected, actual):
            return "Canonical version mismatch. Expected \(expected), got \(actual)."
        case let .canonicalLineCountMismatch(expected, actual):
            return "Canonical line-count mismatch. Expected \(expected), got \(actual)."
        case let .canonicalSHAMismatch(expected, actual):
            return "Canonical line-sequence SHA mismatch. Expected \(expected), got \(actual)."
        case let .canonicalBlockCountMismatch(expected, actual):
            return "Canonical block-count mismatch. Expected \(expected), got \(actual)."
        case let .emptyCanonicalBlock(id):
            return "Canonical block \(id) reconstructs to no lines."
        }
    }
}

public enum Stage8CanonicalOwnership {
    public static let expectedCanonicalFormatVersion = "1.1-canonical-layer-0"

    public static func load(canonicalURL: URL) throws -> Stage8CanonicalOwnershipBook {
        let seal = try Stage8Layer1RebaseSeal.bundled()
        let data = try Data(contentsOf: canonicalURL)
        let canonical = try JSONDecoder().decode(Stage8CanonicalDocument.self, from: data)

        guard canonical.formatVersion == expectedCanonicalFormatVersion else {
            throw Stage8CanonicalOwnershipError.canonicalFormatMismatch(
                expected: expectedCanonicalFormatVersion,
                actual: canonical.formatVersion
            )
        }
        guard canonical.canonicalVersion == seal.targetLayer0.version else {
            throw Stage8CanonicalOwnershipError.canonicalVersionMismatch(
                expected: seal.targetLayer0.version,
                actual: canonical.canonicalVersion
            )
        }
        guard canonical.validation.lineSequenceSHA256 == seal.targetLayer0.lineSequenceSHA256 else {
            throw Stage8CanonicalOwnershipError.canonicalSHAMismatch(
                expected: seal.targetLayer0.lineSequenceSHA256,
                actual: canonical.validation.lineSequenceSHA256
            )
        }

        let blocks = canonical.chunks.flatMap(\.blocks)
        guard blocks.count == seal.expectedContainerCount else {
            throw Stage8CanonicalOwnershipError.canonicalBlockCountMismatch(
                expected: seal.expectedContainerCount,
                actual: blocks.count
            )
        }

        var nextLine = 1
        var containers: [CanonicalOwnershipContainer] = []
        containers.reserveCapacity(blocks.count)

        for (index, block) in blocks.enumerated() {
            let reconstructed = block.reconstructedLines
            guard !reconstructed.isEmpty else {
                throw Stage8CanonicalOwnershipError.emptyCanonicalBlock(block.id)
            }

            let start = nextLine
            let end = start + reconstructed.count - 1
            let canonicalLines = reconstructed.enumerated().map { offset, text in
                CanonicalLine(number: start + offset, text: text)
            }
            let label = block.labelAsWritten ?? reconstructed[0]

            containers.append(
                CanonicalOwnershipContainer(
                    id: String(format: "L1-CNT-%04d", index + 1),
                    layer0BlockID: block.id,
                    layer0BlockType: block.type,
                    labelAsWritten: label,
                    canonicalAnchor: ReadingAnchor(
                        canonicalLayer0Version: canonical.canonicalVersion,
                        startLine: start,
                        endLine: end
                    ),
                    lines: canonicalLines
                )
            )
            nextLine = end + 1
        }

        let lineCount = nextLine - 1
        guard lineCount == seal.targetLayer0.lineCount else {
            throw Stage8CanonicalOwnershipError.canonicalLineCountMismatch(
                expected: seal.targetLayer0.lineCount,
                actual: lineCount
            )
        }

        return Stage8CanonicalOwnershipBook(
            canonicalLayer0Version: canonical.canonicalVersion,
            canonicalLineSequenceSHA256: canonical.validation.lineSequenceSHA256,
            containers: containers
        )
    }
}

private struct Stage8CanonicalDocument: Decodable {
    let formatVersion: String
    let canonicalVersion: String
    let chunks: [Stage8CanonicalChunk]
    let validation: Stage8CanonicalValidation

    enum CodingKeys: String, CodingKey {
        case formatVersion = "format_version"
        case canonicalVersion = "canonical_version"
        case chunks
        case validation
    }
}

private struct Stage8CanonicalValidation: Decodable {
    let lineSequenceSHA256: String

    enum CodingKeys: String, CodingKey {
        case lineSequenceSHA256 = "line_sequence_sha256"
    }
}

private struct Stage8CanonicalChunk: Decodable {
    let blocks: [Stage8CanonicalBlock]
}

private struct Stage8CanonicalBlock: Decodable {
    let id: String
    let type: String
    let dateText: String?
    let heading: String?
    let lines: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case dateText = "date_text"
        case heading
        case lines
    }

    var reconstructedLines: [String] {
        switch type {
        case "dated_entry":
            return [dateText].compactMap { $0 } + lines
        case "section":
            return [heading].compactMap { $0 } + lines
        default:
            return lines
        }
    }

    var labelAsWritten: String? {
        switch type {
        case "dated_entry": return dateText
        case "section": return heading
        default: return lines.first
        }
    }
}
