import Foundation
import Testing
import JJWWReaderCore
import JJWWTypography
@testable import JJWWPagination

@Suite("JJWW Stage 8C Document-Aware Pagination")
struct Stage8CDocumentPaginationTests {
    private var canonicalURL: URL {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let packageRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let repositoryRoot = packageRoot
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return repositoryRoot.appendingPathComponent(
            "jesse-james-and-the-widow-whipple-canonical-v1.1.json"
        )
    }

    @Test("C1 opening clusters retreat as one documentary gesture when the candidate page is too short")
    func openingClusterPlanner() {
        let atoms = [
            atom(group: "prior", start: 0, end: 19, role: .body),
            atom(group: "item", start: 20, end: 29, role: .dateHeading, startsDocument: true),
            atom(group: "item", start: 30, end: 49, role: .sourceHeader),
            atom(group: "item", start: 50, end: 59, role: .sectionTitle),
            atom(group: "item", start: 60, end: 220, role: .body)
        ]
        let zones = DocumentBreakPlanner.keepZones(atoms: atoms, policy: .stage8C)
        let opening = zones.first { $0.reason == .documentOpening }

        #expect(opening?.startLocation == 20)
        #expect(opening?.minimumEndLocation == 132)
        #expect(
            DocumentBreakPlanner.adjustedBreakEnd(
                pageStart: 0,
                proposedEnd: 100,
                keepZones: zones
            ) == 20
        )

        // If the protected object itself begins the page, the paginator must
        // degrade gracefully rather than retreat to an empty leaf.
        #expect(
            DocumentBreakPlanner.adjustedBreakEnd(
                pageStart: 20,
                proposedEnd: 100,
                keepZones: zones
            ) == 100
        )
    }

    @Test("C1 witness and procedural labels stay attached to meaningful following matter")
    func labelClusterPlanner() {
        let atoms = [
            atom(group: "trial", start: 0, end: 90, role: .body),
            atom(group: "trial", start: 91, end: 119, role: .witnessLabel),
            atom(group: "trial", start: 120, end: 260, role: .body)
        ]
        let zones = DocumentBreakPlanner.keepZones(atoms: atoms, policy: .stage8C)
        let label = zones.first { $0.reason == .speakerLabel }

        #expect(label?.startLocation == 91)
        #expect(label?.minimumEndLocation == 152)
        #expect(
            DocumentBreakPlanner.adjustedBreakEnd(
                pageStart: 0,
                proposedEnd: 140,
                keepZones: zones
            ) == 91
        )
    }

    @Test("C2/C3 the May newspaper openings carry body matter with their documentary headers")
    @MainActor
    func earlyNewspaperOpeningsAreNotOrphaned() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        try expectOpening(
            startLine: 24,
            bodyLine: 27,
            in: result
        )
        try expectOpening(
            startLine: 37,
            bodyLine: 40,
            in: result
        )
        try expectOpening(
            startLine: 41,
            bodyLine: 43,
            in: result
        )
        try expectOpening(
            startLine: 44,
            bodyLine: 46,
            in: result
        )
    }

    @Test("C3 protected labels are never the stranded final matter when their testimony continues")
    @MainActor
    func labelsAreNotStrandedAcrossLeaves() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        for index in 0..<(max(0, result.pages.count - 1)) {
            let page = result.pages[index]
            let next = result.pages[index + 1]
            guard let last = page.fragments.last(where: { !$0.text.isEmpty }),
                  let first = next.fragments.first(where: { !$0.text.isEmpty }) else {
                continue
            }
            let protected = last.role == .dateHeading ||
                last.role == .sourceHeader ||
                last.role == .sectionTitle ||
                last.role == .witnessLabel ||
                last.role == .courtLabel ||
                last.role == .counselLabel
            let sameFlow = last.readingUnitID == first.readingUnitID &&
                last.blockID == first.blockID

            if protected && sameFlow {
                let pageFirst = page.fragments.first(where: { !$0.text.isEmpty })
                print(
                    "C3 PAGE-EDGE: page=\(page.pageIndex) " +
                    "pageStartLine=\(pageFirst?.canonicalLine ?? -1) " +
                    "pageStartRole=\(String(describing: pageFirst?.role)) " +
                    "lastLine=\(last.canonicalLine) lastRole=\(last.role) " +
                    "nextLine=\(first.canonicalLine) nextRole=\(first.role) " +
                    "unit=\(last.readingUnitID) block=\(last.blockID) " +
                    "lastText=\(String(last.text.prefix(120))) " +
                    "nextText=\(String(first.text.prefix(120)))"
                )
                #expect(false)
            }
        }
    }

    @Test("C7 document-aware leaves still reconstruct the entire production Edition exactly")
    @MainActor
    func wholeBookCanonicalReconstructionRemainsExact() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        #expect(edition.canonicalLineSequenceSHA256 == "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e")
        #expect(edition.orderedReadingUnits.count == 75)
        #expect(!result.pages.isEmpty)
        #expect(result.pages.allSatisfy { !$0.fragments.isEmpty })

        for unit in edition.orderedReadingUnits {
            #expect(
                result.reconstructedCanonicalText(for: unit.id) ==
                unit.canonicalText
            )
        }

        let grouped = Dictionary(grouping: result.pages, by: \.layoutSegmentID)
        for pages in grouped.values {
            let ordered = pages.sorted { $0.pageIndex < $1.pageIndex }
            for pair in zip(ordered, ordered.dropFirst()) {
                #expect(
                    pair.0.segmentTextRange.upperBound ==
                    pair.1.segmentTextRange.location
                )
            }
        }
    }

    private func atom(
        group: String,
        start: Int,
        end: Int,
        role: TypographyRole,
        startsDocument: Bool = false
    ) -> DocumentBreakAtom {
        DocumentBreakAtom(
            groupID: group,
            startLocation: start,
            endLocation: end,
            role: role,
            startsDocument: startsDocument,
            isEmpty: false
        )
    }

    private func expectOpening(
        startLine: Int,
        bodyLine: Int,
        in result: PaginationResult
    ) throws {
        let page = try #require(
            result.pages.first { page in
                page.fragments.contains {
                    $0.canonicalLine == startLine &&
                    $0.utf16Start == 0
                }
            }
        )
        #expect(
            page.fragments.contains {
                $0.canonicalLine == bodyLine &&
                !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        )
    }
}
