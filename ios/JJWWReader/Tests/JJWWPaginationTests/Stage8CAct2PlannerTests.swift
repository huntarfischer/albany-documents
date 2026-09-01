import Foundation
import Testing
import JJWWReaderCore
import JJWWScrollReader
import JJWWTypography
@testable import JJWWPagination

@Suite("JJWW Stage 8C Act II Documentary Break Planner")
struct Stage8CAct2PlannerTests {
    @Test("Act II keeps a newspaper opening with meaningful body matter")
    func openingClusterCarriesBody() {
        let atoms = [
            atom(id: "prior", start: 0, end: 19, role: .body),
            atom(id: "item", start: 20, end: 29, role: .dateHeading, beginsDocument: true),
            atom(id: "item", start: 30, end: 49, role: .sourceHeader),
            atom(id: "item", start: 50, end: 59, role: .sectionTitle),
            atom(id: "item", start: 60, end: 220, role: .body)
        ]

        let zones = DocumentPaginationPlanner.keepZones(atoms: atoms)
        let opening = zones.first { $0.reason == .documentOpening }

        #expect(opening?.startLocation == 20)
        #expect(opening?.minimumEndLocation == 132)
        #expect(
            DocumentPaginationPlanner.adjustedBreakEnd(
                pageStart: 0,
                proposedEnd: 100,
                atoms: atoms,
                keepZones: zones
            ) == 20
        )
        #expect(
            DocumentPaginationPlanner.adjustedBreakEnd(
                pageStart: 20,
                proposedEnd: 100,
                atoms: atoms,
                keepZones: zones
            ) == 100
        )
    }

    @Test("An enclosing date and source may carry a nested document opening")
    func nestedRequestOpeningStaysAttached() {
        let outer = identity(id: "outer", type: "dated_item", start: 1_172, end: 1_177)
        let request = identity(id: "request", type: "request_document", start: 1_174, end: 1_177)
        let atoms = [
            atom(identity: outer, start: 0, end: 28, role: .dateHeading, beginsDocument: true),
            atom(identity: outer, start: 29, end: 43, role: .sourceHeader),
            atom(identity: request, start: 44, end: 175, role: .sectionTitle, beginsDocument: true),
            atom(identity: request, start: 176, end: 420, role: .body)
        ]

        let zones = DocumentPaginationPlanner.keepZones(atoms: atoms)
        let outerOpening = zones.first {
            $0.reason == .documentOpening && $0.startLocation == 0
        }
        let nestedOpening = zones.first {
            $0.reason == .documentOpening && $0.startLocation == 44
        }

        #expect(outerOpening?.minimumEndLocation == 248)
        #expect(nestedOpening?.minimumEndLocation == 248)
        #expect(
            DocumentPaginationPlanner.adjustedBreakEnd(
                pageStart: 0,
                proposedEnd: 55,
                atoms: atoms,
                keepZones: zones
            ) == 55
        )
        #expect(
            DocumentPaginationPlanner.adjustedBreakEnd(
                pageStart: 0,
                proposedEnd: 200,
                atoms: atoms,
                keepZones: zones
            ) == 200
        )
        #expect(
            DocumentPaginationPlanner.adjustedBreakEnd(
                pageStart: 20,
                proposedEnd: 200,
                atoms: atoms,
                keepZones: zones
            ) == 44
        )
    }

    @Test("Witness and procedural labels carry meaningful following testimony")
    func labelsCarryFollowingMatter() {
        let atoms = [
            atom(id: "trial", start: 0, end: 90, role: .body),
            atom(
                id: "trial",
                start: 91,
                end: 119,
                role: .witnessLabel,
                relationships: [.speakerOrProceduralLabel]
            ),
            atom(id: "trial", start: 120, end: 260, role: .body)
        ]

        let zones = DocumentPaginationPlanner.keepZones(atoms: atoms)
        let label = zones.first { $0.reason == .speakerOrProceduralLabel }

        #expect(label?.startLocation == 91)
        #expect(label?.minimumEndLocation == 152)
        #expect(
            DocumentPaginationPlanner.adjustedBreakEnd(
                pageStart: 0,
                proposedEnd: 140,
                atoms: atoms,
                keepZones: zones
            ) == 91
        )
    }

    @Test("A nearby new documentary object is preferred over a mechanically full edge")
    func preferredBoundaryWinsNearPhysicalEdge() {
        let first = identity(id: "first", type: "dated_item", start: 1, end: 5)
        let second = identity(id: "second", type: "dated_item", start: 6, end: 10)
        let atoms = [
            atom(identity: first, start: 0, end: 400, role: .body),
            atom(identity: second, start: 401, end: 650, role: .body, beginsDocument: true)
        ]

        let zones = DocumentPaginationPlanner.keepZones(atoms: atoms)
        #expect(
            DocumentPaginationPlanner.adjustedBreakEnd(
                pageStart: 0,
                proposedEnd: 500,
                atoms: atoms,
                keepZones: zones
            ) == 401
        )
    }

    @Test("A preferred boundary too early on the leaf does not manufacture a large void")
    func preferredBoundaryMustBeNearEdge() {
        let first = identity(id: "first", type: "dated_item", start: 1, end: 5)
        let second = identity(id: "second", type: "dated_item", start: 6, end: 10)
        let atoms = [
            atom(identity: first, start: 0, end: 199, role: .body),
            atom(identity: second, start: 200, end: 700, role: .body, beginsDocument: true)
        ]

        let zones = DocumentPaginationPlanner.keepZones(atoms: atoms)
        #expect(
            DocumentPaginationPlanner.adjustedBreakEnd(
                pageStart: 0,
                proposedEnd: 500,
                atoms: atoms,
                keepZones: zones
            ) == 500
        )
    }

    private func atom(
        id: String,
        start: Int,
        end: Int,
        role: TypographyRole,
        beginsDocument: Bool = false,
        relationships: [DocumentRelationshipEvidence] = []
    ) -> DocumentPaginationAtom {
        atom(
            identity: identity(id: id, type: "dated_item", start: 1, end: 100),
            start: start,
            end: end,
            role: role,
            beginsDocument: beginsDocument,
            relationships: relationships
        )
    }

    private func atom(
        identity: DocumentIdentity,
        start: Int,
        end: Int,
        role: TypographyRole,
        beginsDocument: Bool = false,
        relationships: [DocumentRelationshipEvidence] = []
    ) -> DocumentPaginationAtom {
        DocumentPaginationAtom(
            groupID: "unit|block",
            startLocation: start,
            endLocation: end,
            role: role,
            evidence: DocumentBoundaryEvidence(
                canonicalLine: identity.canonicalAnchor.startLine,
                documentIdentity: identity,
                semanticTypes: identity.structuralType.map { [$0] } ?? [],
                sourceOccurrenceIDs: [],
                sourceContextIDs: [],
                relationships: relationships,
                beginsDocument: beginsDocument,
                beginsDirectSourceAttribution: role == .sourceHeader
            ),
            isEmpty: false
        )
    }

    private func identity(
        id: String,
        type: String,
        start: Int,
        end: Int
    ) -> DocumentIdentity {
        DocumentIdentity(
            id: "span:\(id)",
            basis: .structuralSpan,
            structuralType: type,
            sourceID: nil,
            canonicalAnchor: ReadingAnchor(
                canonicalLayer0Version: "1.1",
                startLine: start,
                endLine: end
            )
        )
    }
}
