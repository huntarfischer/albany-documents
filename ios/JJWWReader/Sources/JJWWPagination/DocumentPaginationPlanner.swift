import Foundation
import JJWWReaderCore
import JJWWScrollReader
import JJWWTypography

struct DocumentPaginationPolicy: Equatable, Sendable {
    let minimumOpeningBodyCharacters: Int
    let minimumLabelBodyCharacters: Int
    let minimumHeadingBodyCharacters: Int
    let minimumPreferredFillRatio: Double

    init(
        minimumOpeningBodyCharacters: Int,
        minimumLabelBodyCharacters: Int,
        minimumHeadingBodyCharacters: Int,
        minimumPreferredFillRatio: Double
    ) {
        self.minimumOpeningBodyCharacters = max(1, minimumOpeningBodyCharacters)
        self.minimumLabelBodyCharacters = max(1, minimumLabelBodyCharacters)
        self.minimumHeadingBodyCharacters = max(1, minimumHeadingBodyCharacters)
        self.minimumPreferredFillRatio = min(1, max(0, minimumPreferredFillRatio))
    }

    static let stage8CAct2 = DocumentPaginationPolicy(
        minimumOpeningBodyCharacters: 72,
        minimumLabelBodyCharacters: 32,
        minimumHeadingBodyCharacters: 32,
        minimumPreferredFillRatio: 0.72
    )
}

struct DocumentPaginationAtom: Equatable, Sendable {
    let groupID: String
    let startLocation: Int
    let endLocation: Int
    let role: TypographyRole
    let evidence: DocumentBoundaryEvidence
    let isEmpty: Bool
}

struct DocumentKeepZone: Equatable, Sendable {
    enum Reason: String, Equatable, Sendable {
        case documentOpening
        case speakerOrProceduralLabel
        case displayHeading
    }

    let startLocation: Int
    let minimumEndLocation: Int
    let reason: Reason
}

struct DocumentBoundaryCandidate: Equatable, Sendable {
    let location: Int
    let disposition: DocumentBreakDisposition
}

enum DocumentPaginationPlanner {
    static func keepZones(
        atoms: [DocumentPaginationAtom],
        policy: DocumentPaginationPolicy = .stage8CAct2
    ) -> [DocumentKeepZone] {
        var zones: [DocumentKeepZone] = []

        for index in atoms.indices {
            let atom = atoms[index]
            guard !atom.isEmpty else { continue }

            if shouldBeginOpeningCluster(at: index, atoms: atoms),
               let zone = openingZone(
                    startingAt: index,
                    atoms: atoms,
                    minimumBodyCharacters: policy.minimumOpeningBodyCharacters
               ) {
                zones.append(zone)
            }

            if isSpeakerOrProceduralLabel(atom),
               !isContinuationOfLabelCluster(at: index, atoms: atoms),
               let zone = relationshipZone(
                    startingAt: index,
                    atoms: atoms,
                    minimumBodyCharacters: policy.minimumLabelBodyCharacters,
                    reason: .speakerOrProceduralLabel,
                    relationshipPredicate: isSpeakerOrProceduralLabel
               ) {
                zones.append(zone)
            }

            if isDisplayHeading(atom),
               !isOpeningHeader(atom.role),
               let zone = relationshipZone(
                    startingAt: index,
                    atoms: atoms,
                    minimumBodyCharacters: policy.minimumHeadingBodyCharacters,
                    reason: .displayHeading,
                    relationshipPredicate: isDisplayHeading
               ) {
                zones.append(zone)
            }
        }

        return deduplicated(zones)
    }

    static func boundaryCandidates(
        atoms: [DocumentPaginationAtom]
    ) -> [DocumentBoundaryCandidate] {
        guard atoms.count > 1 else { return [] }
        var candidates: [DocumentBoundaryCandidate] = []

        for index in 1..<atoms.count {
            let lhs = atoms[index - 1]
            let rhs = atoms[index]
            guard lhs.groupID == rhs.groupID else {
                candidates.append(
                    DocumentBoundaryCandidate(
                        location: rhs.startLocation,
                        disposition: .preferred
                    )
                )
                continue
            }
            guard !rhs.isEmpty else { continue }

            let disposition = disposition(between: lhs, and: rhs)
            candidates.append(
                DocumentBoundaryCandidate(
                    location: rhs.startLocation,
                    disposition: disposition
                )
            )
        }

        return candidates
    }

    static func adjustedBreakEnd(
        pageStart: Int,
        proposedEnd: Int,
        atoms: [DocumentPaginationAtom],
        keepZones: [DocumentKeepZone],
        policy: DocumentPaginationPolicy = .stage8CAct2
    ) -> Int {
        guard proposedEnd > pageStart else { return proposedEnd }

        let violatingZones = keepZones.filter { zone in
            zone.startLocation > pageStart &&
            zone.startLocation < proposedEnd &&
            proposedEnd < zone.minimumEndLocation
        }
        let effectiveViolations = violatingZones.filter { zone in
            !keepZones.contains { enclosing in
                enclosing.startLocation == pageStart &&
                enclosing.startLocation < zone.startLocation &&
                enclosing.minimumEndLocation >= zone.minimumEndLocation
            }
        }
        if let retreat = effectiveViolations.max(by: {
            $0.startLocation < $1.startLocation
        })?.startLocation {
            return retreat
        }

        let capacity = proposedEnd - pageStart
        let minimumPreferredLocation = pageStart + Int(
            floor(Double(capacity) * policy.minimumPreferredFillRatio)
        )
        let candidates = boundaryCandidates(atoms: atoms)
            .filter {
                $0.disposition == .preferred &&
                $0.location > pageStart &&
                $0.location <= proposedEnd &&
                $0.location >= minimumPreferredLocation &&
                !isInsideActiveParentKeepZone(
                    $0.location,
                    pageStart: pageStart,
                    keepZones: keepZones
                )
            }
            .sorted { $0.location < $1.location }

        return candidates.last?.location ?? proposedEnd
    }

    private static func isInsideActiveParentKeepZone(
        _ location: Int,
        pageStart: Int,
        keepZones: [DocumentKeepZone]
    ) -> Bool {
        keepZones.contains { zone in
            zone.startLocation >= pageStart &&
            zone.startLocation < location &&
            location < zone.minimumEndLocation
        }
    }

    private static func disposition(
        between lhs: DocumentPaginationAtom,
        and rhs: DocumentPaginationAtom
    ) -> DocumentBreakDisposition {
        if shouldKeepTogether(lhs: lhs, rhs: rhs) {
            return .keep
        }
        if lhs.evidence.relationships.contains(.separator) {
            return .preferred
        }
        if lhs.evidence.documentIdentity.id != rhs.evidence.documentIdentity.id {
            return .preferred
        }
        if let lhsSource = lhs.evidence.documentIdentity.sourceID,
           let rhsSource = rhs.evidence.documentIdentity.sourceID,
           lhsSource != rhsSource {
            return .preferred
        }
        return DocumentPaginationLaw.disposition(
            between: lhs.evidence,
            and: rhs.evidence
        )
    }

    private static func shouldKeepTogether(
        lhs: DocumentPaginationAtom,
        rhs: DocumentPaginationAtom
    ) -> Bool {
        if isOpeningHeader(lhs.role) && !rhs.isEmpty {
            return true
        }
        if isSpeakerOrProceduralLabel(lhs) && !rhs.isEmpty {
            return true
        }
        if isDisplayHeading(lhs) && !rhs.isEmpty {
            return true
        }
        return false
    }

    private static func shouldBeginOpeningCluster(
        at index: Int,
        atoms: [DocumentPaginationAtom]
    ) -> Bool {
        let atom = atoms[index]
        if atom.evidence.beginsDocument { return true }
        if atom.role == .dateHeading { return true }
        if atom.role == .sourceHeader {
            guard index > 0 else { return true }
            let previous = atoms[..<index]
                .reversed()
                .first { $0.groupID == atom.groupID && !$0.isEmpty }
            guard let previous else { return true }
            if isOpeningHeader(previous.role) { return false }
            if previous.evidence.documentIdentity.id != atom.evidence.documentIdentity.id {
                return true
            }
            if let previousSource = previous.evidence.documentIdentity.sourceID,
               let source = atom.evidence.documentIdentity.sourceID,
               previousSource != source {
                return true
            }
        }
        return false
    }

    private static func openingZone(
        startingAt startIndex: Int,
        atoms: [DocumentPaginationAtom],
        minimumBodyCharacters: Int
    ) -> DocumentKeepZone? {
        let start = atoms[startIndex]
        var cursor = startIndex

        while cursor < atoms.count,
              atoms[cursor].groupID == start.groupID {
            let candidate = atoms[cursor]
            if candidate.isEmpty {
                cursor += 1
                continue
            }
            if cursor > startIndex,
               candidate.role == .dateHeading {
                return nil
            }
            if isOpeningHeader(candidate.role) {
                cursor += 1
                continue
            }
            break
        }

        guard cursor < atoms.count else { return nil }
        let body = atoms[cursor]
        guard body.groupID == start.groupID,
              !body.isEmpty else {
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

    private static func relationshipZone(
        startingAt startIndex: Int,
        atoms: [DocumentPaginationAtom],
        minimumBodyCharacters: Int,
        reason: DocumentKeepZone.Reason,
        relationshipPredicate: (DocumentPaginationAtom) -> Bool
    ) -> DocumentKeepZone? {
        let start = atoms[startIndex]
        var cursor = startIndex + 1

        while cursor < atoms.count,
              atoms[cursor].groupID == start.groupID,
              (atoms[cursor].isEmpty || relationshipPredicate(atoms[cursor])) {
            cursor += 1
        }

        guard cursor < atoms.count else { return nil }
        let body = atoms[cursor]
        guard body.groupID == start.groupID,
              !body.isEmpty,
              body.role != .dateHeading else {
            return nil
        }

        let available = max(1, body.endLocation - body.startLocation)
        let required = min(available, minimumBodyCharacters)
        return DocumentKeepZone(
            startLocation: start.startLocation,
            minimumEndLocation: body.startLocation + required,
            reason: reason
        )
    }

    private static func isContinuationOfLabelCluster(
        at index: Int,
        atoms: [DocumentPaginationAtom]
    ) -> Bool {
        guard index > 0 else { return false }
        let atom = atoms[index]
        let previous = atoms[index - 1]
        return previous.groupID == atom.groupID &&
            isSpeakerOrProceduralLabel(previous)
    }

    private static func isOpeningHeader(_ role: TypographyRole) -> Bool {
        role == .dateHeading || role == .sourceHeader || role == .sectionTitle
    }

    private static func isSpeakerOrProceduralLabel(
        _ atom: DocumentPaginationAtom
    ) -> Bool {
        atom.role == .witnessLabel ||
        atom.role == .courtLabel ||
        atom.role == .counselLabel ||
        atom.evidence.relationships.contains(.speakerOrProceduralLabel)
    }

    private static func isDisplayHeading(
        _ atom: DocumentPaginationAtom
    ) -> Bool {
        atom.role == .sectionTitle ||
        atom.evidence.relationships.contains(.displayHeading)
    }

    private static func deduplicated(
        _ zones: [DocumentKeepZone]
    ) -> [DocumentKeepZone] {
        var seen: Set<String> = []
        return zones
            .sorted {
                if $0.startLocation == $1.startLocation {
                    return $0.minimumEndLocation < $1.minimumEndLocation
                }
                return $0.startLocation < $1.startLocation
            }
            .filter { zone in
                let key = "\(zone.startLocation)|\(zone.minimumEndLocation)|\(zone.reason.rawValue)"
                return seen.insert(key).inserted
            }
    }
}
