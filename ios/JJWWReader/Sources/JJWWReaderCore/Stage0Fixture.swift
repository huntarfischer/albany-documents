import Foundation

public enum Stage0FixtureError: Error, Equatable, CustomStringConvertible {
    case manifestMissing
    case invalidFixtureVersion(String)
    case canonicalFormatMismatch(expected: String, actual: String)
    case canonicalVersionMismatch(expected: String, actual: String)
    case canonicalLineCountMismatch(expected: Int, actual: Int)
    case canonicalSHAMismatch(expected: String, actual: String)
    case invalidRange(start: Int, end: Int, lineCount: Int)

    public var description: String {
        switch self {
        case .manifestMissing:
            return "Stage 0 fixture manifest is missing."
        case let .invalidFixtureVersion(version):
            return "Unsupported Stage 0 fixture version: \(version)"
        case let .canonicalFormatMismatch(expected, actual):
            return "Canonical format mismatch. Expected \(expected), got \(actual)."
        case let .canonicalVersionMismatch(expected, actual):
            return "Canonical version mismatch. Expected \(expected), got \(actual)."
        case let .canonicalLineCountMismatch(expected, actual):
            return "Canonical line-count mismatch. Expected \(expected), got \(actual)."
        case let .canonicalSHAMismatch(expected, actual):
            return "Canonical line-sequence SHA mismatch. Expected \(expected), got \(actual)."
        case let .invalidRange(start, end, lineCount):
            return "Invalid canonical range \(start)-\(end) for \(lineCount) lines."
        }
    }
}

public enum Stage0Fixture {
    public static let expectedFixtureVersion = "0.1"

    /// Builds the five-section Stage 0 edition directly from the sealed canonical Layer 0 v1.1 JSON.
    ///
    /// Stage 0 does not patch, normalize, or otherwise alter canonical text at runtime.
    public static func load(canonicalURL: URL) throws -> Edition {
        let manifest = try loadManifest()
        guard manifest.fixtureVersion == expectedFixtureVersion else {
            throw Stage0FixtureError.invalidFixtureVersion(manifest.fixtureVersion)
        }

        let data = try Data(contentsOf: canonicalURL)
        let canonical = try JSONDecoder().decode(CanonicalLayer0Document.self, from: data)

        guard canonical.formatVersion == manifest.canonicalSource.formatVersion else {
            throw Stage0FixtureError.canonicalFormatMismatch(
                expected: manifest.canonicalSource.formatVersion,
                actual: canonical.formatVersion
            )
        }

        guard canonical.canonicalVersion == manifest.canonicalSource.layer0Version else {
            throw Stage0FixtureError.canonicalVersionMismatch(
                expected: manifest.canonicalSource.layer0Version,
                actual: canonical.canonicalVersion
            )
        }

        guard canonical.validation.lineSequenceSHA256 == manifest.canonicalSource.lineSequenceSHA256 else {
            throw Stage0FixtureError.canonicalSHAMismatch(
                expected: manifest.canonicalSource.lineSequenceSHA256,
                actual: canonical.validation.lineSequenceSHA256
            )
        }

        let lines = canonical.reconstructedLines()
        guard lines.count == manifest.canonicalSource.lineCount else {
            throw Stage0FixtureError.canonicalLineCountMismatch(
                expected: manifest.canonicalSource.lineCount,
                actual: lines.count
            )
        }

        let units = try manifest.edition.units.map { descriptor in
            try makeReadingUnit(
                descriptor: descriptor,
                canonicalVersion: manifest.canonicalSource.layer0Version,
                lines: lines
            )
        }

        return Edition(
            id: manifest.edition.id,
            title: manifest.edition.title,
            version: manifest.edition.version,
            canonicalLayer0Version: manifest.canonicalSource.layer0Version,
            canonicalLineSequenceSHA256: manifest.canonicalSource.lineSequenceSHA256,
            readingUnits: units
        )
    }

    private static func loadManifest() throws -> FixtureManifest {
        guard let url = Bundle.module.url(
            forResource: "five-section-fixture-manifest-v0.1",
            withExtension: "json"
        ) else {
            throw Stage0FixtureError.manifestMissing
        }

        return try JSONDecoder().decode(
            FixtureManifest.self,
            from: Data(contentsOf: url)
        )
    }

    private static func makeReadingUnit(
        descriptor: ReadingUnitDescriptor,
        canonicalVersion: String,
        lines: [String]
    ) throws -> ReadingUnit {
        let unitAnchor = try makeAnchor(
            start: descriptor.startLine,
            end: descriptor.endLine,
            canonicalVersion: canonicalVersion,
            lineCount: lines.count
        )

        let blocks = try descriptor.blocks.map { block in
            let anchor = try makeAnchor(
                start: block.startLine,
                end: block.endLine,
                canonicalVersion: canonicalVersion,
                lineCount: lines.count
            )

            return DocumentBlock(
                id: block.id,
                kind: block.kind,
                canonicalAnchor: anchor,
                sourcePassageID: block.sourcePassageID,
                lines: (block.startLine...block.endLine).map { lineNumber in
                    CanonicalLine(
                        number: lineNumber,
                        text: lines[lineNumber - 1]
                    )
                }
            )
        }

        return ReadingUnit(
            id: descriptor.id,
            sequence: descriptor.sequence,
            kind: descriptor.kind,
            canonicalAnchor: unitAnchor,
            sourcePresentation: descriptor.sourcePresentation,
            typographyProfile: TypographyProfile(id: descriptor.typographyProfileID),
            materialProfile: MaterialProfile(id: descriptor.materialProfileID),
            blocks: blocks
        )
    }

    private static func makeAnchor(
        start: Int,
        end: Int,
        canonicalVersion: String,
        lineCount: Int
    ) throws -> ReadingAnchor {
        guard start > 0, end >= start, end <= lineCount else {
            throw Stage0FixtureError.invalidRange(
                start: start,
                end: end,
                lineCount: lineCount
            )
        }

        return ReadingAnchor(
            canonicalLayer0Version: canonicalVersion,
            startLine: start,
            endLine: end
        )
    }
}

private struct FixtureManifest: Decodable {
    let fixtureVersion: String
    let canonicalSource: CanonicalSourceDescriptor
    let edition: EditionDescriptor
}

private struct CanonicalSourceDescriptor: Decodable {
    let layer0Version: String
    let formatVersion: String
    let lineCount: Int
    let lineSequenceSHA256: String
}

private struct EditionDescriptor: Decodable {
    let id: String
    let title: String
    let version: String
    let units: [ReadingUnitDescriptor]
}

private struct ReadingUnitDescriptor: Decodable {
    let id: String
    let sequence: Int
    let kind: ReadingUnitKind
    let startLine: Int
    let endLine: Int
    let sourcePresentation: SourcePresentation?
    let typographyProfileID: String
    let materialProfileID: String
    let blocks: [DocumentBlockDescriptor]
}

private struct DocumentBlockDescriptor: Decodable {
    let id: String
    let kind: DocumentBlockKind
    let startLine: Int
    let endLine: Int
    let sourcePassageID: String?
}

private struct CanonicalLayer0Document: Decodable {
    let formatVersion: String
    let canonicalVersion: String
    let chunks: [CanonicalChunk]
    let validation: CanonicalValidation

    enum CodingKeys: String, CodingKey {
        case formatVersion = "format_version"
        case canonicalVersion = "canonical_version"
        case chunks
        case validation
    }

    func reconstructedLines() -> [String] {
        chunks.flatMap { chunk in
            chunk.blocks.flatMap(\.reconstructedLines)
        }
    }
}

private struct CanonicalValidation: Decodable {
    let lineSequenceSHA256: String

    enum CodingKeys: String, CodingKey {
        case lineSequenceSHA256 = "line_sequence_sha256"
    }
}

private struct CanonicalChunk: Decodable {
    let blocks: [CanonicalBlock]
}

private struct CanonicalBlock: Decodable {
    let type: String
    let dateText: String?
    let heading: String?
    let lines: [String]

    enum CodingKeys: String, CodingKey {
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
}
