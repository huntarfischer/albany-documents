import Foundation
import JJWWTypography

public struct DocumentPaginationPolicy: Codable, Equatable, Hashable, Sendable {
    public let version: String
    public let protectDocumentOpenings: Bool
    public let protectSpeakerLabels: Bool
    public let minimumOpeningBodyCharacters: Int
    public let minimumLabelBodyCharacters: Int

    public init(
        version: String,
        protectDocumentOpenings: Bool,
        protectSpeakerLabels: Bool,
        minimumOpeningBodyCharacters: Int,
        minimumLabelBodyCharacters: Int
    ) {
        self.version = version
        self.protectDocumentOpenings = protectDocumentOpenings
        self.protectSpeakerLabels = protectSpeakerLabels
        self.minimumOpeningBodyCharacters = max(1, minimumOpeningBodyCharacters)
        self.minimumLabelBodyCharacters = max(1, minimumLabelBodyCharacters)
    }

    public static let stage8C = DocumentPaginationPolicy(
        version: "stage8c-document-breaks-v0.2",
        protectDocumentOpenings: true,
        protectSpeakerLabels: true,
        minimumOpeningBodyCharacters: 72,
        minimumLabelBodyCharacters: 32
    )

    public static let disabled = DocumentPaginationPolicy(
        version: "document-breaks-disabled-v0.1",
        protectDocumentOpenings: false,
        protectSpeakerLabels: false,
        minimumOpeningBodyCharacters: 1,
        minimumLabelBodyCharacters: 1
    )
}

struct DocumentBreakAtom: Equatable, Sendable {
    let groupID: String
    let startLocation: Int
    let endLocation: Int
    let role: TypographyRole
    let startsDocument: Bool
    let isEmpty: Bool
}

struct DocumentKeepZone: Equatable, Sendable {
    enum Reason: String, Equatable, Sendable {
        case documentOpening
        case speakerLabel
    }

    let startLocation: Int
    let minimumEndLocation: Int
    let reason: Reason
}

enum DocumentBreakPlanner {
    static func keepZones(
        atoms: [DocumentBreakAtom],
        policy: DocumentPaginationPolicy
    ) -> [DocumentKeepZone] {
        var zones: [DocumentKeepZone] = []

        for index in atoms.indices {
            let atom = atoms[index]
            guard !atom.isEmpty else { continue }

            let beginsProtectedOpening = atom.startsDocument || (
                isOpeningHeader(atom.role) &&
                !precededByOpeningHeader(index: index, atoms: atoms)
            )
            if policy.protectDocumentOpenings,
               beginsProtectedOpening {
                if let zone = openingZone(
                    startingAt: index,
                    atoms: atoms,
                    minimumBodyCharacters: policy.minimumOpeningBodyCharacters
                ) {
                    zones.append(zone)
                }
            }

            if policy.protectSpeakerLabels,
               isSpeakerLabel(atom.role),
               !precededBySpeakerLabel(index: index, atoms: atoms) {
                if let zone = labelZone(
                    startingAt: index,
                    atoms: atoms,
                    minimumBodyCharacters: policy.minimumLabelBodyCharacters
                ) {
                    zones.append(zone)
                }
            }
        }

        return zones.sorted {
            if $0.startLocation == $1.startLocation {
                return $0.minimumEndLocation < $1.minimumEndLocation
            }
            return $0.startLocation < $1.startLocation
        }
    }

    static func adjustedBreakEnd(
        pageStart: Int,
        proposedEnd: Int,
        keepZones: [DocumentKeepZone]
    ) -> Int {
        guard proposedEnd > pageStart else { return proposedEnd }

        let violating = keepZones.filter { zone in
            zone.startLocation > pageStart &&
            zone.startLocation < proposedEnd &&
            proposedEnd < zone.minimumEndLocation
        }

        // The latest protected object on the candidate page is the smallest
        // lawful retreat. Earlier objects remain untouched whenever possible.
        return violating.last?.startLocation ?? proposedEnd
    }

    private static func openingZone(
        startingAt startIndex: Int,
        atoms: [DocumentBreakAtom],
        minimumBodyCharacters: Int
    ) -> DocumentKeepZone? {
        let start = atoms[startIndex]
        var cursor = startIndex

        if isOpeningHeader(start.role) {
            while cursor < atoms.count,
                  atoms[cursor].groupID == start.groupID,
                  (atoms[cursor].isEmpty || isOpeningHeader(atoms[cursor].role)) {
                cursor += 1
            }
        }

        guard cursor < atoms.count else { return nil }
        let body = atoms[cursor]
        guard body.groupID == start.groupID,
              !body.isEmpty,
              !body.startsDocument || cursor == startIndex else {
            return nil
        }

        let available = max(1, body.endLocation - body.startLocation)
        let required = min(available, minimumBodyCharacters)
        let minimumEnd = body.startLocation + required
        guard minimumEnd > start.startLocation else { return nil }

        return DocumentKeepZone(
            startLocation: start.startLocation,
            minimumEndLocation: minimumEnd,
            reason: .documentOpening
        )
    }

    private static func labelZone(
        startingAt startIndex: Int,
        atoms: [DocumentBreakAtom],
        minimumBodyCharacters: Int
    ) -> DocumentKeepZone? {
        let start = atoms[startIndex]
        var cursor = startIndex + 1

        while cursor < atoms.count,
              atoms[cursor].groupID == start.groupID,
              (atoms[cursor].isEmpty || isSpeakerLabel(atoms[cursor].role)) {
            cursor += 1
        }

        guard cursor < atoms.count else { return nil }
        let body = atoms[cursor]
        guard body.groupID == start.groupID,
              !body.isEmpty,
              !body.startsDocument else {
            return nil
        }

        let available = max(1, body.endLocation - body.startLocation)
        let required = min(available, minimumBodyCharacters)
        return DocumentKeepZone(
            startLocation: start.startLocation,
            minimumEndLocation: body.startLocation + required,
            reason: .speakerLabel
        )
    }

    private static func precededByOpeningHeader(
        index: Int,
        atoms: [DocumentBreakAtom]
    ) -> Bool {
        guard index > 0 else { return false }
        let previous = atoms[index - 1]
        return previous.groupID == atoms[index].groupID &&
            isOpeningHeader(previous.role)
    }

    private static func precededBySpeakerLabel(
        index: Int,
        atoms: [DocumentBreakAtom]
    ) -> Bool {
        guard index > 0 else { return false }
        let previous = atoms[index - 1]
        return previous.groupID == atoms[index].groupID &&
            isSpeakerLabel(previous.role)
    }

    private static func isOpeningHeader(_ role: TypographyRole) -> Bool {
        role == .dateHeading || role == .sourceHeader || role == .sectionTitle
    }

    private static func isSpeakerLabel(_ role: TypographyRole) -> Bool {
        role == .witnessLabel || role == .courtLabel || role == .counselLabel
    }
}
