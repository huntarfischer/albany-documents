import Foundation

public struct Stage8Layer1SemanticsBook: Equatable, Sendable {
    public let structuralSpans: [DocumentSemanticSpan]
    public let sourceOccurrences: [DocumentSourceOccurrence]
    public let sourceContexts: [DocumentSourceContext]

    public init(
        structuralSpans: [DocumentSemanticSpan],
        sourceOccurrences: [DocumentSourceOccurrence],
        sourceContexts: [DocumentSourceContext]
    ) {
        self.structuralSpans = structuralSpans
        self.sourceOccurrences = sourceOccurrences
        self.sourceContexts = sourceContexts
    }

    public func semantics(for anchor: ReadingAnchor) -> DocumentSemantics {
        DocumentSemantics(
            structuralSpans: structuralSpans.filter { $0.canonicalAnchor.intersects(anchor) },
            sourceOccurrences: sourceOccurrences.filter { occurrence in
                occurrence.attributionAnchor.intersects(anchor) ||
                occurrence.passageAnchor?.intersects(anchor) == true
            },
            sourceContexts: sourceContexts.filter { $0.canonicalAnchor.intersects(anchor) }
        )
    }
}

public enum Stage8Layer1SemanticsError: Error, Equatable, CustomStringConvertible {
    case structuralIndexMissing
    case sourceRegistryMissing
    case structuralFormatMismatch(String)
    case sourceFormatMismatch(String)
    case sourceLayer0ReferenceMismatch
    case geometryChanged
    case structuralUnitCountMismatch(expected: Int, actual: Int)
    case sourceCountMismatch(expected: Int, actual: Int)
    case sourceOccurrenceCountMismatch(expected: Int, actual: Int)
    case sourceContextCountMismatch(expected: Int, actual: Int)
    case unknownContainer(String)
    case unknownSource(String)
    case unknownOccurrence(String)
    case invalidAnchor(String)

    public var description: String {
        switch self {
        case .structuralIndexMissing:
            return "Stage 8 Layer 1 structural index is missing."
        case .sourceRegistryMissing:
            return "Stage 8 Layer 1 source registry is missing."
        case let .structuralFormatMismatch(actual):
            return "Unexpected Layer 1 structural format: \(actual)."
        case let .sourceFormatMismatch(actual):
            return "Unexpected Layer 1 source format: \(actual)."
        case .sourceLayer0ReferenceMismatch:
            return "Layer 1 semantics do not match the source side of the Stage 8 rebase seal."
        case .geometryChanged:
            return "Layer 1 semantic anchors cannot be rebased because canonical line geometry changed."
        case let .structuralUnitCountMismatch(expected, actual):
            return "Expected \(expected) Layer 1 structural units, got \(actual)."
        case let .sourceCountMismatch(expected, actual):
            return "Expected \(expected) Layer 1 sources, got \(actual)."
        case let .sourceOccurrenceCountMismatch(expected, actual):
            return "Expected \(expected) Layer 1 source occurrences, got \(actual)."
        case let .sourceContextCountMismatch(expected, actual):
            return "Expected \(expected) Layer 1 source contexts, got \(actual)."
        case let .unknownContainer(id):
            return "Layer 1 semantics reference unknown ownership container \(id)."
        case let .unknownSource(id):
            return "Layer 1 semantics reference unknown source \(id)."
        case let .unknownOccurrence(id):
            return "Layer 1 source context references unknown occurrence \(id)."
        case let .invalidAnchor(id):
            return "Layer 1 semantic object \(id) has an invalid canonical anchor."
        }
    }
}

public enum Stage8Layer1Semantics {
    public static let structuralFormatVersion = "2.0-layer-1-structure"
    public static let sourceFormatVersion = "2.0-layer-1-sources"

    public static func load(ownership: Stage8CanonicalOwnershipBook) throws -> Stage8Layer1SemanticsBook {
        let seal = try Stage8Layer1RebaseSeal.bundled()
        guard seal.geometryUnchanged else {
            throw Stage8Layer1SemanticsError.geometryChanged
        }
        guard ownership.canonicalLayer0Version == seal.targetLayer0.version,
              ownership.canonicalLineSequenceSHA256 == seal.targetLayer0.lineSequenceSHA256 else {
            throw Stage8Layer1SemanticsError.sourceLayer0ReferenceMismatch
        }

        let structural = try bundledStructuralIndex()
        let registry = try bundledSourceRegistry()

        guard structural.formatVersion == structuralFormatVersion else {
            throw Stage8Layer1SemanticsError.structuralFormatMismatch(structural.formatVersion)
        }
        guard registry.formatVersion == sourceFormatVersion else {
            throw Stage8Layer1SemanticsError.sourceFormatMismatch(registry.formatVersion)
        }
        guard structural.layer0Reference.lineCount == seal.sourceLayer0.lineCount,
              structural.layer0Reference.lineSequenceSHA256 == seal.sourceLayer0.lineSequenceSHA256 else {
            throw Stage8Layer1SemanticsError.sourceLayer0ReferenceMismatch
        }
        guard structural.units.count == seal.expectedStructuralUnitCount else {
            throw Stage8Layer1SemanticsError.structuralUnitCountMismatch(
                expected: seal.expectedStructuralUnitCount,
                actual: structural.units.count
            )
        }
        guard registry.sources.count == seal.expectedSourceCount else {
            throw Stage8Layer1SemanticsError.sourceCountMismatch(
                expected: seal.expectedSourceCount,
                actual: registry.sources.count
            )
        }
        guard registry.occurrences.count == seal.expectedSourceOccurrenceCount else {
            throw Stage8Layer1SemanticsError.sourceOccurrenceCountMismatch(
                expected: seal.expectedSourceOccurrenceCount,
                actual: registry.occurrences.count
            )
        }
        guard registry.contexts.count == seal.expectedSourceContextCount else {
            throw Stage8Layer1SemanticsError.sourceContextCountMismatch(
                expected: seal.expectedSourceContextCount,
                actual: registry.contexts.count
            )
        }

        let knownContainers = Set(ownership.containers.map(\.id))
        let sourceByID = Dictionary(uniqueKeysWithValues: registry.sources.map { source in
            (
                source.sourceID,
                DocumentSourceIdentity(
                    id: source.sourceID,
                    titleAsWritten: source.titleAsWritten,
                    sourceType: source.sourceType
                )
            )
        })
        let knownOccurrenceIDs = Set(registry.occurrences.map(\.occurrenceID))

        let spans = try structural.units.map { unit -> DocumentSemanticSpan in
            guard knownContainers.contains(unit.parentContainerID) else {
                throw Stage8Layer1SemanticsError.unknownContainer(unit.parentContainerID)
            }
            let anchor = try targetAnchor(
                id: unit.unitID,
                startLine: unit.lineStart,
                endLine: unit.lineEnd,
                ownership: ownership
            )
            let label = rebasedLabel(
                unit.labelAsWritten,
                anchor: anchor,
                containerID: unit.parentContainerID,
                seal: seal
            )
            return DocumentSemanticSpan(
                id: unit.unitID,
                type: unit.unitType,
                labelAsWritten: label,
                canonicalAnchor: anchor,
                parentContainerID: unit.parentContainerID,
                parentUnitID: unit.parentUnitID,
                boundaryBasis: unit.boundaryBasis,
                sourceContextIDs: unit.sourceContextIDs ?? []
            )
        }

        let occurrences = try registry.occurrences.map { occurrence -> DocumentSourceOccurrence in
            guard knownContainers.contains(occurrence.containingContainerID) else {
                throw Stage8Layer1SemanticsError.unknownContainer(occurrence.containingContainerID)
            }
            guard let source = sourceByID[occurrence.sourceID] else {
                throw Stage8Layer1SemanticsError.unknownSource(occurrence.sourceID)
            }
            let attributionAnchor = try targetAnchor(
                id: occurrence.occurrenceID,
                startLine: occurrence.attributionLineStart,
                endLine: occurrence.attributionLineEnd,
                ownership: ownership
            )
            let passageAnchor: ReadingAnchor?
            if let start = occurrence.passageLineStart,
               let end = occurrence.passageLineEnd {
                passageAnchor = try targetAnchor(
                    id: occurrence.occurrenceID + ".passage",
                    startLine: start,
                    endLine: end,
                    ownership: ownership
                )
            } else {
                passageAnchor = nil
            }
            return DocumentSourceOccurrence(
                id: occurrence.occurrenceID,
                source: source,
                role: occurrence.role,
                attributionAnchor: attributionAnchor,
                passageAnchor: passageAnchor,
                containingContainerID: occurrence.containingContainerID
            )
        }

        let contexts = try registry.contexts.map { context -> DocumentSourceContext in
            guard let source = sourceByID[context.sourceID] else {
                throw Stage8Layer1SemanticsError.unknownSource(context.sourceID)
            }
            guard knownOccurrenceIDs.contains(context.attributionOccurrenceID) else {
                throw Stage8Layer1SemanticsError.unknownOccurrence(context.attributionOccurrenceID)
            }
            return DocumentSourceContext(
                id: context.contextID,
                source: source,
                canonicalAnchor: try targetAnchor(
                    id: context.contextID,
                    startLine: context.lineStart,
                    endLine: context.lineEnd,
                    ownership: ownership
                ),
                relationship: context.relationship,
                basis: context.basis,
                attributionOccurrenceID: context.attributionOccurrenceID
            )
        }

        return Stage8Layer1SemanticsBook(
            structuralSpans: spans,
            sourceOccurrences: occurrences,
            sourceContexts: contexts
        )
    }

    private static func targetAnchor(
        id: String,
        startLine: Int,
        endLine: Int,
        ownership: Stage8CanonicalOwnershipBook
    ) throws -> ReadingAnchor {
        guard startLine >= 1,
              endLine >= startLine,
              endLine <= ownership.lines.count else {
            throw Stage8Layer1SemanticsError.invalidAnchor(id)
        }
        return ReadingAnchor(
            canonicalLayer0Version: ownership.canonicalLayer0Version,
            startLine: startLine,
            endLine: endLine
        )
    }

    private static func rebasedLabel(
        _ label: String,
        anchor: ReadingAnchor,
        containerID: String,
        seal: Stage8Layer1RebaseSeal
    ) -> String {
        guard let correction = seal.containerCorrections.first(where: {
            $0.containerID == containerID &&
            anchor.startLine <= $0.lineStart &&
            $0.lineStart <= anchor.endLine &&
            label == $0.oldLabel
        }) else {
            return label
        }
        return correction.newLabel
    }

    private static func bundledStructuralIndex() throws -> RawStructuralIndex {
        guard let url = Bundle.module.url(
            forResource: "layer-1-structural-index-v2",
            withExtension: "json"
        ) else {
            throw Stage8Layer1SemanticsError.structuralIndexMissing
        }
        return try JSONDecoder().decode(RawStructuralIndex.self, from: Data(contentsOf: url))
    }

    private static func bundledSourceRegistry() throws -> RawSourceRegistry {
        guard let url = Bundle.module.url(
            forResource: "layer-1-source-registry-v2",
            withExtension: "json"
        ) else {
            throw Stage8Layer1SemanticsError.sourceRegistryMissing
        }
        return try JSONDecoder().decode(RawSourceRegistry.self, from: Data(contentsOf: url))
    }
}

private struct RawStructuralIndex: Decodable {
    let formatVersion: String
    let layer0Reference: RawLayer0Reference
    let units: [RawStructuralUnit]

    enum CodingKeys: String, CodingKey {
        case formatVersion = "format_version"
        case layer0Reference = "layer0_reference"
        case units
    }
}

private struct RawLayer0Reference: Decodable {
    let lineCount: Int
    let lineSequenceSHA256: String

    enum CodingKeys: String, CodingKey {
        case lineCount = "line_count"
        case lineSequenceSHA256 = "line_sequence_sha256"
    }
}

private struct RawStructuralUnit: Decodable {
    let unitID: String
    let unitType: String
    let labelAsWritten: String
    let lineStart: Int
    let lineEnd: Int
    let parentContainerID: String
    let parentUnitID: String?
    let boundaryBasis: String
    let sourceContextIDs: [String]?

    enum CodingKeys: String, CodingKey {
        case unitID = "unit_id"
        case unitType = "unit_type"
        case labelAsWritten = "label_as_written"
        case lineStart = "line_start"
        case lineEnd = "line_end"
        case parentContainerID = "parent_container_id"
        case parentUnitID = "parent_unit_id"
        case boundaryBasis = "boundary_basis"
        case sourceContextIDs = "source_context_ids"
    }
}

private struct RawSourceRegistry: Decodable {
    let formatVersion: String
    let sources: [RawSource]
    let occurrences: [RawSourceOccurrence]
    let contexts: [RawSourceContext]

    enum CodingKeys: String, CodingKey {
        case formatVersion = "format_version"
        case sources
        case occurrences
        case contexts
    }
}

private struct RawSource: Decodable {
    let sourceID: String
    let titleAsWritten: String
    let sourceType: String

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case titleAsWritten = "title_as_written"
        case sourceType = "source_type"
    }
}

private struct RawSourceOccurrence: Decodable {
    let occurrenceID: String
    let sourceID: String
    let role: String
    let attributionLineStart: Int
    let attributionLineEnd: Int
    let containingContainerID: String
    let passageLineStart: Int?
    let passageLineEnd: Int?

    enum CodingKeys: String, CodingKey {
        case occurrenceID = "occurrence_id"
        case sourceID = "source_id"
        case role
        case attributionLineStart = "attribution_line_start"
        case attributionLineEnd = "attribution_line_end"
        case containingContainerID = "containing_container_id"
        case passageLineStart = "passage_line_start"
        case passageLineEnd = "passage_line_end"
    }
}

private struct RawSourceContext: Decodable {
    let contextID: String
    let sourceID: String
    let lineStart: Int
    let lineEnd: Int
    let relationship: String
    let basis: String
    let attributionOccurrenceID: String

    enum CodingKeys: String, CodingKey {
        case contextID = "context_id"
        case sourceID = "source_id"
        case lineStart = "line_start"
        case lineEnd = "line_end"
        case relationship
        case basis
        case attributionOccurrenceID = "attribution_occurrence_id"
    }
}
