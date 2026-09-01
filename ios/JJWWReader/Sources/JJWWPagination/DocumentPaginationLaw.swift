import Foundation
import JJWWReaderCore

public enum DocumentBreakDisposition: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case preferred
    case allowed
    case avoid
    case keep
}

public enum DocumentIdentityBasis: String, Codable, Equatable, Hashable, Sendable {
    case structuralSpan
    case sourceOccurrence
    case sourceContext
    case ownershipBlock
}

public struct DocumentIdentity: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let basis: DocumentIdentityBasis
    public let structuralType: String?
    public let sourceID: String?
    public let canonicalAnchor: ReadingAnchor

    public init(
        id: String,
        basis: DocumentIdentityBasis,
        structuralType: String?,
        sourceID: String?,
        canonicalAnchor: ReadingAnchor
    ) {
        self.id = id
        self.basis = basis
        self.structuralType = structuralType
        self.sourceID = sourceID
        self.canonicalAnchor = canonicalAnchor
    }
}

public enum DocumentRelationshipEvidence: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case displayHeading
    case speakerOrProceduralLabel
    case testimonyOpening
    case imagePlaceholder
    case separator
}

public struct DocumentBoundaryEvidence: Codable, Equatable, Sendable {
    public let canonicalLine: Int
    public let documentIdentity: DocumentIdentity
    public let semanticTypes: [String]
    public let sourceOccurrenceIDs: [String]
    public let sourceContextIDs: [String]
    public let relationships: [DocumentRelationshipEvidence]
    public let beginsDocument: Bool
    public let beginsDirectSourceAttribution: Bool

    public init(
        canonicalLine: Int,
        documentIdentity: DocumentIdentity,
        semanticTypes: [String],
        sourceOccurrenceIDs: [String],
        sourceContextIDs: [String],
        relationships: [DocumentRelationshipEvidence],
        beginsDocument: Bool,
        beginsDirectSourceAttribution: Bool
    ) {
        self.canonicalLine = canonicalLine
        self.documentIdentity = documentIdentity
        self.semanticTypes = semanticTypes
        self.sourceOccurrenceIDs = sourceOccurrenceIDs
        self.sourceContextIDs = sourceContextIDs
        self.relationships = relationships
        self.beginsDocument = beginsDocument
        self.beginsDirectSourceAttribution = beginsDirectSourceAttribution
    }
}

public struct DocumentPaginationEvidenceInventory: Equatable, Sendable {
    public let semanticTypeCounts: [String: Int]
    public let sourceTypeCounts: [String: Int]
    public let sourceRelationshipCounts: [String: Int]
    public let uniqueStructuralSpanCount: Int
    public let uniqueSourceOccurrenceCount: Int
    public let uniqueSourceContextCount: Int

    public init(
        semanticTypeCounts: [String: Int],
        sourceTypeCounts: [String: Int],
        sourceRelationshipCounts: [String: Int],
        uniqueStructuralSpanCount: Int,
        uniqueSourceOccurrenceCount: Int,
        uniqueSourceContextCount: Int
    ) {
        self.semanticTypeCounts = semanticTypeCounts
        self.sourceTypeCounts = sourceTypeCounts
        self.sourceRelationshipCounts = sourceRelationshipCounts
        self.uniqueStructuralSpanCount = uniqueStructuralSpanCount
        self.uniqueSourceOccurrenceCount = uniqueSourceOccurrenceCount
        self.uniqueSourceContextCount = uniqueSourceContextCount
    }
}

/// Stage 8C Act I defines documentary pagination law without changing pagination behavior.
///
/// Identity comes only from the manuscript evidence already present in Layer 1. Visual
/// families, typography profiles, and material profiles are deliberately absent here.
public enum DocumentPaginationLaw {
    public static let version = "stage8c-act1-document-law-v0.1"

    public static let documentObjectTypes: Set<String> = [
        "dated_item",
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

    public static func evidence(
        for canonicalLine: Int,
        in block: DocumentBlock
    ) -> DocumentBoundaryEvidence {
        let spans = block.semanticSpans
            .filter { $0.canonicalAnchor.contains(line: canonicalLine) }
            .sorted { $0.id < $1.id }
        let occurrences = block.sourceOccurrences
            .filter { $0.applies(to: canonicalLine) }
            .sorted { $0.id < $1.id }
        let contexts = block.sourceContexts
            .filter { $0.canonicalAnchor.contains(line: canonicalLine) }
            .sorted { $0.id < $1.id }
        let identity = documentIdentity(
            for: canonicalLine,
            in: block,
            spans: spans,
            occurrences: occurrences,
            contexts: contexts
        )

        var relationships: Set<DocumentRelationshipEvidence> = []
        if spans.contains(where: { $0.type == "uppercase_display_line" }) {
            relationships.insert(.displayHeading)
        }
        if spans.contains(where: { $0.type == "procedural_or_speaker_label" }) {
            relationships.insert(.speakerOrProceduralLabel)
        }
        if spans.contains(where: {
            $0.type == "witness_testimony_segment" &&
            $0.canonicalAnchor.startLine == canonicalLine
        }) {
            relationships.insert(.testimonyOpening)
        }
        if spans.contains(where: { $0.type == "image_placeholder" }) {
            relationships.insert(.imagePlaceholder)
        }
        if spans.contains(where: { $0.type == "separator" }) {
            relationships.insert(.separator)
        }

        return DocumentBoundaryEvidence(
            canonicalLine: canonicalLine,
            documentIdentity: identity,
            semanticTypes: Array(Set(spans.map(\.type))).sorted(),
            sourceOccurrenceIDs: occurrences.map(\.id),
            sourceContextIDs: contexts.map(\.id),
            relationships: relationships.sorted { $0.rawValue < $1.rawValue },
            beginsDocument: identity.canonicalAnchor.startLine == canonicalLine,
            beginsDirectSourceAttribution: occurrences.contains {
                $0.role == "direct_attribution" &&
                $0.attributionAnchor.startLine == canonicalLine
            }
        )
    }

    public static func documentIdentity(
        for canonicalLine: Int,
        in block: DocumentBlock
    ) -> DocumentIdentity {
        let spans = block.semanticSpans.filter {
            $0.canonicalAnchor.contains(line: canonicalLine)
        }
        let occurrences = block.sourceOccurrences.filter {
            $0.applies(to: canonicalLine)
        }
        let contexts = block.sourceContexts.filter {
            $0.canonicalAnchor.contains(line: canonicalLine)
        }
        return documentIdentity(
            for: canonicalLine,
            in: block,
            spans: spans,
            occurrences: occurrences,
            contexts: contexts
        )
    }

    /// Act I only classifies the simplest boundary law. Act II will add opening-cluster
    /// and relationship laws without changing this vocabulary.
    public static func disposition(
        between lhs: DocumentBoundaryEvidence,
        and rhs: DocumentBoundaryEvidence
    ) -> DocumentBreakDisposition {
        lhs.documentIdentity.id == rhs.documentIdentity.id ? .allowed : .preferred
    }

    public static func inventory(in edition: Edition) -> DocumentPaginationEvidenceInventory {
        var spansByID: [String: DocumentSemanticSpan] = [:]
        var occurrencesByID: [String: DocumentSourceOccurrence] = [:]
        var contextsByID: [String: DocumentSourceContext] = [:]

        for block in edition.orderedReadingUnits.flatMap(\.blocks) {
            for span in block.semanticSpans { spansByID[span.id] = span }
            for occurrence in block.sourceOccurrences { occurrencesByID[occurrence.id] = occurrence }
            for context in block.sourceContexts { contextsByID[context.id] = context }
        }

        var semanticTypeCounts: [String: Int] = [:]
        for span in spansByID.values {
            semanticTypeCounts[span.type, default: 0] += 1
        }

        var sourceTypeCounts: [String: Int] = [:]
        for occurrence in occurrencesByID.values {
            sourceTypeCounts[occurrence.source.sourceType, default: 0] += 1
        }

        var sourceRelationshipCounts: [String: Int] = [:]
        for context in contextsByID.values {
            sourceRelationshipCounts[context.relationship, default: 0] += 1
        }

        return DocumentPaginationEvidenceInventory(
            semanticTypeCounts: semanticTypeCounts,
            sourceTypeCounts: sourceTypeCounts,
            sourceRelationshipCounts: sourceRelationshipCounts,
            uniqueStructuralSpanCount: spansByID.count,
            uniqueSourceOccurrenceCount: occurrencesByID.count,
            uniqueSourceContextCount: contextsByID.count
        )
    }

    private static func documentIdentity(
        for canonicalLine: Int,
        in block: DocumentBlock,
        spans: [DocumentSemanticSpan],
        occurrences: [DocumentSourceOccurrence],
        contexts: [DocumentSourceContext]
    ) -> DocumentIdentity {
        let sourceID = preferredOccurrence(
            for: canonicalLine,
            from: occurrences
        )?.source.id ?? preferredContext(from: contexts)?.source.id

        let documentSpans = spans
            .filter { documentObjectTypes.contains($0.type) }
            .sorted(by: moreSpecificSpan)
        if let span = documentSpans.first {
            return DocumentIdentity(
                id: "span:\(span.id)",
                basis: .structuralSpan,
                structuralType: span.type,
                sourceID: sourceID,
                canonicalAnchor: span.canonicalAnchor
            )
        }

        if let occurrence = preferredOccurrence(
            for: canonicalLine,
            from: occurrences
        ) {
            let anchor = occurrence.passageAnchor ?? occurrence.attributionAnchor
            return DocumentIdentity(
                id: "source-occurrence:\(occurrence.id)",
                basis: .sourceOccurrence,
                structuralType: nil,
                sourceID: occurrence.source.id,
                canonicalAnchor: anchor
            )
        }

        if let context = preferredContext(from: contexts) {
            return DocumentIdentity(
                id: "source-context:\(context.id)",
                basis: .sourceContext,
                structuralType: nil,
                sourceID: context.source.id,
                canonicalAnchor: context.canonicalAnchor
            )
        }

        return DocumentIdentity(
            id: "block:\(block.id)",
            basis: .ownershipBlock,
            structuralType: nil,
            sourceID: nil,
            canonicalAnchor: block.canonicalAnchor
        )
    }

    private static func preferredOccurrence(
        for canonicalLine: Int,
        from occurrences: [DocumentSourceOccurrence]
    ) -> DocumentSourceOccurrence? {
        occurrences.sorted { lhs, rhs in
            let lhsPassage = lhs.passageAnchor?.contains(line: canonicalLine) == true
            let rhsPassage = rhs.passageAnchor?.contains(line: canonicalLine) == true
            if lhsPassage != rhsPassage { return lhsPassage }

            let lhsAnchor = lhs.passageAnchor ?? lhs.attributionAnchor
            let rhsAnchor = rhs.passageAnchor ?? rhs.attributionAnchor
            let lhsLength = lhsAnchor.endLine - lhsAnchor.startLine
            let rhsLength = rhsAnchor.endLine - rhsAnchor.startLine
            if lhsLength != rhsLength { return lhsLength < rhsLength }
            return lhs.id < rhs.id
        }.first
    }

    private static func preferredContext(
        from contexts: [DocumentSourceContext]
    ) -> DocumentSourceContext? {
        contexts.sorted { lhs, rhs in
            let lhsLength = lhs.canonicalAnchor.endLine - lhs.canonicalAnchor.startLine
            let rhsLength = rhs.canonicalAnchor.endLine - rhs.canonicalAnchor.startLine
            if lhsLength != rhsLength { return lhsLength < rhsLength }
            return lhs.id < rhs.id
        }.first
    }

    private static func moreSpecificSpan(
        _ lhs: DocumentSemanticSpan,
        _ rhs: DocumentSemanticSpan
    ) -> Bool {
        let lhsLength = lhs.canonicalAnchor.endLine - lhs.canonicalAnchor.startLine
        let rhsLength = rhs.canonicalAnchor.endLine - rhs.canonicalAnchor.startLine
        if lhsLength != rhsLength { return lhsLength < rhsLength }

        let lhsNested = lhs.parentUnitID != nil
        let rhsNested = rhs.parentUnitID != nil
        if lhsNested != rhsNested { return lhsNested }

        if lhs.canonicalAnchor.startLine != rhs.canonicalAnchor.startLine {
            return lhs.canonicalAnchor.startLine > rhs.canonicalAnchor.startLine
        }
        return lhs.id < rhs.id
    }
}
