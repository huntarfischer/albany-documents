import Foundation

public enum Stage8ProductionEditionError: Error, Equatable, CustomStringConvertible {
    case missingOwnershipContainer(String)
    case emptyReadingUnit(String)

    public var description: String {
        switch self {
        case let .missingOwnershipContainer(id):
            return "Stage 8 production Edition is missing ownership container \(id)."
        case let .emptyReadingUnit(id):
            return "Stage 8 production ReadingUnit \(id) has no ownership blocks."
        }
    }
}

public enum Stage8ProductionEdition {
    public static func load(canonicalURL: URL) throws -> Edition {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let semantics = try Stage8Layer1Semantics.load(ownership: ownership)
        let map = try Stage8EditionMap.load(canonicalURL: canonicalURL)

        let units = try map.entries.map { entry in
            let containers = try entry.containerIDs.map { id -> CanonicalOwnershipContainer in
                guard let container = ownership.container(id: id) else {
                    throw Stage8ProductionEditionError.missingOwnershipContainer(id)
                }
                return container
            }

            guard !containers.isEmpty else {
                throw Stage8ProductionEditionError.emptyReadingUnit(entry.id)
            }

            let blocks = containers.enumerated().map { offset, container in
                let blockSemantics = semantics.semantics(for: container.canonicalAnchor)
                return DocumentBlock(
                    id: "block-\(container.id.lowercased())",
                    kind: container.id == "L1-CNT-0001" ? .frontMatter : .sourceText,
                    canonicalAnchor: container.canonicalAnchor,
                    sourcePassageID: sourcePassageID(
                        for: entry.sourcePresentation,
                        containerOffset: offset,
                        containerCount: containers.count
                    ),
                    lines: container.lines,
                    semantics: blockSemantics.isEmpty ? nil : blockSemantics
                )
            }

            return ReadingUnit(
                id: entry.id,
                sequence: entry.sequence,
                kind: .section,
                canonicalAnchor: entry.canonicalAnchor,
                sourcePresentation: entry.sourcePresentation,
                typographyProfile: entry.typographyProfile,
                materialProfile: entry.materialProfile,
                blocks: blocks
            )
        }

        return Edition(
            id: map.id,
            title: map.title,
            version: map.version,
            canonicalLayer0Version: map.canonicalLayer0Version,
            canonicalLineSequenceSHA256: map.canonicalLineSequenceSHA256,
            readingUnits: units
        )
    }

    private static func sourcePassageID(
        for presentation: SourcePresentation?,
        containerOffset: Int,
        containerCount: Int
    ) -> String? {
        guard let presentation, !presentation.passageIDs.isEmpty else {
            return nil
        }

        if presentation.passageIDs.count == containerCount,
           presentation.passageIDs.indices.contains(containerOffset) {
            return presentation.passageIDs[containerOffset]
        }

        if presentation.passageIDs.count == 1 {
            return presentation.passageIDs[0]
        }

        return presentation.passageIDs.indices.contains(containerOffset)
            ? presentation.passageIDs[containerOffset]
            : nil
    }
}
