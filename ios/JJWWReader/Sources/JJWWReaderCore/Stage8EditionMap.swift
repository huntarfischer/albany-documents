import Foundation

public enum Stage8PresentationFamily: String, Codable, CaseIterable, Equatable, Sendable {
    case unclassified
    case editorialInterior
    case periodical
    case pamphlet
    case courtLegal
    case bookExcerpt
    case standaloneDocument
    case displayArtifact
    case referenceBackMatter
}

public struct Stage8EditionMapEntry: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let sequence: Int
    public let containerIDs: [String]
    public let canonicalAnchor: ReadingAnchor
    public let presentationFamily: Stage8PresentationFamily
    public let presentationVariant: String?
    public let typographyProfile: TypographyProfile
    public let materialProfile: MaterialProfile
    public let sourcePresentation: SourcePresentation?

    public init(
        id: String,
        sequence: Int,
        containerIDs: [String],
        canonicalAnchor: ReadingAnchor,
        presentationFamily: Stage8PresentationFamily,
        presentationVariant: String?,
        typographyProfile: TypographyProfile,
        materialProfile: MaterialProfile,
        sourcePresentation: SourcePresentation?
    ) {
        self.id = id
        self.sequence = sequence
        self.containerIDs = containerIDs
        self.canonicalAnchor = canonicalAnchor
        self.presentationFamily = presentationFamily
        self.presentationVariant = presentationVariant
        self.typographyProfile = typographyProfile
        self.materialProfile = materialProfile
        self.sourcePresentation = sourcePresentation
    }

    public var isClassified: Bool {
        presentationFamily != .unclassified
    }
}

public struct Stage8EditionMapBook: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let version: String
    public let canonicalLayer0Version: String
    public let canonicalLineSequenceSHA256: String
    public let entries: [Stage8EditionMapEntry]

    public init(
        id: String,
        title: String,
        version: String,
        canonicalLayer0Version: String,
        canonicalLineSequenceSHA256: String,
        entries: [Stage8EditionMapEntry]
    ) {
        self.id = id
        self.title = title
        self.version = version
        self.canonicalLayer0Version = canonicalLayer0Version
        self.canonicalLineSequenceSHA256 = canonicalLineSequenceSHA256
        self.entries = entries
    }

    public var containerIDs: [String] { entries.flatMap(\.containerIDs) }
    public var unclassifiedEntries: [Stage8EditionMapEntry] { entries.filter { !$0.isClassified } }

    public func entry(id: String) -> Stage8EditionMapEntry? {
        entries.first { $0.id == id }
    }

    public func entry(containing canonicalLine: Int) -> Stage8EditionMapEntry? {
        entries.first { $0.canonicalAnchor.contains(line: canonicalLine) }
    }
}

public enum Stage8EditionMapError: Error, Equatable, CustomStringConvertible {
    case manifestMissing
    case canonicalReferenceMismatch
    case emptyGroup(String)
    case unknownContainer(String)
    case duplicateContainer(String)
    case noncontiguousGroup(String)
    case classificationOverlapsGroup(String)
    case duplicateClassification(String)
    case incompleteOwnershipMap

    public var description: String {
        switch self {
        case .manifestMissing:
            return "Stage 8 production Edition map manifest is missing."
        case .canonicalReferenceMismatch:
            return "Stage 8 production Edition map does not target the loaded canonical ownership spine."
        case let .emptyGroup(id):
            return "Stage 8 Edition map group \(id) has no ownership containers."
        case let .unknownContainer(id):
            return "Stage 8 Edition map references unknown ownership container \(id)."
        case let .duplicateContainer(id):
            return "Stage 8 Edition map consumes ownership container \(id) more than once."
        case let .noncontiguousGroup(id):
            return "Stage 8 Edition map group \(id) does not contain adjacent ownership containers in canonical order."
        case let .classificationOverlapsGroup(id):
            return "Stage 8 classification for \(id) overlaps an authored multi-container group."
        case let .duplicateClassification(id):
            return "Stage 8 Edition map classifies ownership container \(id) more than once."
        case .incompleteOwnershipMap:
            return "Stage 8 Edition map does not consume the complete ownership spine exactly once."
        }
    }
}

public enum Stage8EditionMap {
    public static func load(canonicalURL: URL) throws -> Stage8EditionMapBook {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let manifest = try bundledManifest()

        guard manifest.canonicalLayer0Version == ownership.canonicalLayer0Version,
              manifest.canonicalLineSequenceSHA256 == ownership.canonicalLineSequenceSHA256 else {
            throw Stage8EditionMapError.canonicalReferenceMismatch
        }

        let ownershipIndex = Dictionary(
            uniqueKeysWithValues: ownership.containers.enumerated().map { ($0.element.id, $0.offset) }
        )
        var groupByContainerID: [String: Stage8EditionMapGroup] = [:]

        for group in manifest.groups {
            guard let firstID = group.containerIDs.first else {
                throw Stage8EditionMapError.emptyGroup(group.id)
            }

            var indices: [Int] = []
            for containerID in group.containerIDs {
                guard let index = ownershipIndex[containerID] else {
                    throw Stage8EditionMapError.unknownContainer(containerID)
                }
                guard groupByContainerID[containerID] == nil else {
                    throw Stage8EditionMapError.duplicateContainer(containerID)
                }
                groupByContainerID[containerID] = group
                indices.append(index)
            }

            let expected = Array(indices[0]..<(indices[0] + indices.count))
            guard indices == expected,
                  ownership.containers[indices[0]].id == firstID else {
                throw Stage8EditionMapError.noncontiguousGroup(group.id)
            }
        }

        var classificationByContainerID: [String: Stage8EditionMapClassificationRule] = [:]
        for rule in manifest.classifications {
            for containerID in rule.containerIDs {
                guard ownershipIndex[containerID] != nil else {
                    throw Stage8EditionMapError.unknownContainer(containerID)
                }
                guard groupByContainerID[containerID] == nil else {
                    throw Stage8EditionMapError.classificationOverlapsGroup(containerID)
                }
                guard classificationByContainerID[containerID] == nil else {
                    throw Stage8EditionMapError.duplicateClassification(containerID)
                }
                classificationByContainerID[containerID] = rule
            }
        }

        var entries: [Stage8EditionMapEntry] = []
        var index = 0

        while index < ownership.containers.count {
            let container = ownership.containers[index]

            if let group = groupByContainerID[container.id] {
                guard group.containerIDs.first == container.id else {
                    index += 1
                    continue
                }

                let resolved = try group.containerIDs.map { id -> CanonicalOwnershipContainer in
                    guard let container = ownership.container(id: id) else {
                        throw Stage8EditionMapError.unknownContainer(id)
                    }
                    return container
                }
                let first = resolved[0]
                let last = resolved[resolved.count - 1]

                entries.append(
                    Stage8EditionMapEntry(
                        id: group.id,
                        sequence: entries.count,
                        containerIDs: group.containerIDs,
                        canonicalAnchor: ReadingAnchor(
                            canonicalLayer0Version: ownership.canonicalLayer0Version,
                            startLine: first.canonicalAnchor.startLine,
                            endLine: last.canonicalAnchor.endLine
                        ),
                        presentationFamily: group.presentationFamily,
                        presentationVariant: group.presentationVariant,
                        typographyProfile: TypographyProfile(id: group.typographyProfileID),
                        materialProfile: MaterialProfile(id: group.materialProfileID),
                        sourcePresentation: group.sourcePresentation
                    )
                )
                index += group.containerIDs.count
            } else {
                let classification = classificationByContainerID[container.id]
                entries.append(
                    Stage8EditionMapEntry(
                        id: manifest.defaults.idPrefix + container.id.lowercased(),
                        sequence: entries.count,
                        containerIDs: [container.id],
                        canonicalAnchor: container.canonicalAnchor,
                        presentationFamily: classification?.presentationFamily ?? manifest.defaults.presentationFamily,
                        presentationVariant: classification?.presentationVariant,
                        typographyProfile: TypographyProfile(
                            id: classification?.typographyProfileID ?? manifest.defaults.typographyProfileID
                        ),
                        materialProfile: MaterialProfile(
                            id: classification?.materialProfileID ?? manifest.defaults.materialProfileID
                        ),
                        sourcePresentation: nil
                    )
                )
                index += 1
            }
        }

        guard entries.flatMap(\.containerIDs) == ownership.containers.map(\.id) else {
            throw Stage8EditionMapError.incompleteOwnershipMap
        }

        return Stage8EditionMapBook(
            id: manifest.editionID,
            title: manifest.editionTitle,
            version: manifest.editionVersion,
            canonicalLayer0Version: manifest.canonicalLayer0Version,
            canonicalLineSequenceSHA256: manifest.canonicalLineSequenceSHA256,
            entries: entries
        )
    }

    private static func bundledManifest() throws -> Stage8EditionMapManifest {
        guard let url = Bundle.module.url(
            forResource: "stage8-edition-map-v1",
            withExtension: "json"
        ) else {
            throw Stage8EditionMapError.manifestMissing
        }
        return try JSONDecoder().decode(Stage8EditionMapManifest.self, from: Data(contentsOf: url))
    }
}

private struct Stage8EditionMapManifest: Decodable {
    let formatVersion: String
    let canonicalLayer0Version: String
    let canonicalLineSequenceSHA256: String
    let editionID: String
    let editionTitle: String
    let editionVersion: String
    let defaults: Stage8EditionMapDefaults
    let groups: [Stage8EditionMapGroup]
    let classifications: [Stage8EditionMapClassificationRule]
}

private struct Stage8EditionMapDefaults: Decodable {
    let idPrefix: String
    let presentationFamily: Stage8PresentationFamily
    let typographyProfileID: String
    let materialProfileID: String
}

private struct Stage8EditionMapClassificationRule: Decodable, Equatable {
    let containerIDs: [String]
    let presentationFamily: Stage8PresentationFamily
    let presentationVariant: String?
    let typographyProfileID: String
    let materialProfileID: String
}

private struct Stage8EditionMapGroup: Decodable, Equatable {
    let id: String
    let containerIDs: [String]
    let presentationFamily: Stage8PresentationFamily
    let presentationVariant: String?
    let typographyProfileID: String
    let materialProfileID: String
    let sourcePresentation: SourcePresentation?
}
