import Foundation
import Testing
import JJWWReaderCore
import JJWWScrollReader
import JJWWTypography
@testable import JJWWPagination

@Suite("JJWW Stage 8C Act II Nested Keep Precedence")
struct Stage8CAct2NestedKeepPrecedenceTests {
    @Test("A leaf before nested openings retreats to the outer opening first")
    func outerOpeningWinsWhenBothAreAhead() {
        let outer = identity(id: "outer", type: "dated_item", start: 1_172, end: 1_177)
        let request = identity(id: "request", type: "request_document", start: 1_174, end: 1_177)
        let atoms = [
            atom(identity: outer, start: 0, end: 49, role: .body),
            atom(identity: outer, start: 50, end: 79, role: .dateHeading, beginsDocument: true),
            atom(identity: outer, start: 80, end: 99, role: .sourceHeader),
            atom(identity: request, start: 100, end: 180, role: .sectionTitle, beginsDocument: true),
            atom(identity: request, start: 181, end: 420, role: .body)
        ]

        let zones = DocumentPaginationPlanner.keepZones(atoms: atoms)
        #expect(
            DocumentPaginationPlanner.adjustedBreakEnd(
                pageStart: 0,
                proposedEnd: 220,
                atoms: atoms,
                keepZones: zones
            ) == 50
        )
    }

    @Test("A leaf already inside the outer opening may retreat to the nested opening")
    func nestedOpeningWinsAfterOuterHasBegun() {
        let outer = identity(id: "outer", type: "dated_item", start: 1_172, end: 1_177)
        let request = identity(id: "request", type: "request_document", start: 1_174, end: 1_177)
        let atoms = [
            atom(identity: outer, start: 0, end: 49, role: .body),
            atom(identity: outer, start: 50, end: 79, role: .dateHeading, beginsDocument: true),
            atom(identity: outer, start: 80, end: 99, role: .sourceHeader),
            atom(identity: request, start: 100, end: 180, role: .sectionTitle, beginsDocument: true),
            atom(identity: request, start: 181, end: 420, role: .body)
        ]

        let zones = DocumentPaginationPlanner.keepZones(atoms: atoms)
        #expect(
            DocumentPaginationPlanner.adjustedBreakEnd(
                pageStart: 80,
                proposedEnd: 220,
                atoms: atoms,
                keepZones: zones
            ) == 100
        )
    }

    private func atom(
        identity: DocumentIdentity,
        start: Int,
        end: Int,
        role: TypographyRole,
        beginsDocument: Bool = false
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
                relationships: [],
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
