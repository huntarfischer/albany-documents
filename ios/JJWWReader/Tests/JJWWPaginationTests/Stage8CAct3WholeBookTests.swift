import Foundation
import Testing
import JJWWReaderCore
import JJWWScrollReader
@testable import JJWWPagination

@Suite("JJWW Stage 8C Act III Whole-Book Pagination")
struct Stage8CAct3WholeBookTests {
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

    @Test("Act III representative documentary species all reach Pages with their openings intact")
    @MainActor
    func representativeSpeciesSurvivePagination() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)
        let species = [
            "confession_document",
            "trial_source_section",
            "official_examination_document",
            "historical_work_section",
            "farewell_document",
            "bibliography_section"
        ]

        for type in species {
            let specimen = try #require(firstSpan(ofType: type, in: edition))
            let openingPage = try #require(
                result.pages.first { page in
                    page.fragments.contains {
                        $0.readingUnitID == specimen.unit.id &&
                        $0.blockID == specimen.block.id &&
                        $0.canonicalLine == specimen.span.canonicalAnchor.startLine &&
                        $0.utf16Start == 0
                    }
                }
            )

            if specimen.span.canonicalAnchor.endLine > specimen.span.canonicalAnchor.startLine {
                #expect(
                    openingPage.fragments.contains { fragment in
                        fragment.readingUnitID == specimen.unit.id &&
                        fragment.blockID == specimen.block.id &&
                        fragment.canonicalLine > specimen.span.canonicalAnchor.startLine &&
                        fragment.canonicalLine <= specimen.span.canonicalAnchor.endLine &&
                        hasText(fragment)
                    },
                    "\(type) opening should carry meaningful following matter"
                )
            }
        }
    }

    @Test("Act III complete pagination remains gapless, nonempty, ordered, and canonically exact")
    @MainActor
    func wholeBookRemainsExact() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        #expect(edition.canonicalLineSequenceSHA256 == "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e")
        #expect(edition.orderedReadingUnits.count == 75)
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).count == 82)
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).flatMap(\.lines).count == 2_069)
        #expect(!result.pages.isEmpty)
        #expect(result.pages.allSatisfy { !$0.fragments.isEmpty })

        for (expectedIndex, page) in result.pages.enumerated() {
            #expect(page.pageIndex == expectedIndex)
            #expect(page.segmentTextRange.length > 0)
        }

        let visibleFragments = result.pages.flatMap(\.fragments).filter(hasText)
        #expect(visibleFragments.first?.canonicalLine == 1)
        #expect(visibleFragments.last?.canonicalLine == 2_069)

        for unit in edition.orderedReadingUnits {
            #expect(result.reconstructedCanonicalText(for: unit.id) == unit.canonicalText)
        }

        let grouped = Dictionary(grouping: result.pages, by: \.layoutSegmentID)
        for pages in grouped.values {
            let ordered = pages.sorted { $0.pageIndex < $1.pageIndex }
            for pair in zip(ordered, ordered.dropFirst()) {
                #expect(pair.0.segmentTextRange.upperBound == pair.1.segmentTextRange.location)
            }
        }
    }

    @Test("Act III no real page boundary cuts a planner KEEP relationship")
    @MainActor
    func noKeepRelationshipIsCut() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)
        let blocks = blockLookup(in: edition)

        var inspectedWholeLineBoundaries = 0
        var preferredBreaks = 0
        var allowedBreaks = 0
        var keepBreaks = 0

        for pair in zip(result.pages, result.pages.dropFirst()) {
            guard pair.0.layoutSegmentID == pair.1.layoutSegmentID,
                  let lhs = pair.0.fragments.last(where: hasText),
                  let rhs = pair.1.fragments.first(where: hasText),
                  lhs.canonicalLine != rhs.canonicalLine,
                  rhs.utf16Start == 0,
                  let lhsBlock = blocks[lhs.blockID],
                  let rhsBlock = blocks[rhs.blockID],
                  let lhsLine = lhsBlock.lines.first(where: { $0.number == lhs.canonicalLine }),
                  lhs.utf16EndExclusive == (lhsLine.text as NSString).length else {
                continue
            }

            inspectedWholeLineBoundaries += 1
            let atoms = [
                atom(for: lhs, block: lhsBlock, start: 0),
                atom(for: rhs, block: rhsBlock, start: 2)
            ]
            let disposition = try #require(
                DocumentPaginationPlanner.boundaryCandidates(atoms: atoms).first?.disposition
            )
            switch disposition {
            case .preferred:
                preferredBreaks += 1
            case .allowed:
                allowedBreaks += 1
            case .keep:
                keepBreaks += 1
            case .avoid:
                break
            }
        }

        #expect(inspectedWholeLineBoundaries > 50)
        #expect(preferredBreaks > 0)
        #expect(allowedBreaks > 0)
        #expect(keepBreaks == 0)
    }

    private func firstSpan(
        ofType type: String,
        in edition: Edition
    ) -> (unit: ReadingUnit, block: DocumentBlock, span: DocumentSemanticSpan)? {
        for unit in edition.orderedReadingUnits {
            for block in unit.blocks {
                if let span = block.semanticSpans.first(where: { $0.type == type }) {
                    return (unit, block, span)
                }
            }
        }
        return nil
    }

    private func blockLookup(in edition: Edition) -> [String: DocumentBlock] {
        Dictionary(
            uniqueKeysWithValues: edition.orderedReadingUnits
                .flatMap(\.blocks)
                .map { ($0.id, $0) }
        )
    }

    private func atom(
        for fragment: PageTextFragment,
        block: DocumentBlock,
        start: Int
    ) -> DocumentPaginationAtom {
        let text = block.lines.first(where: { $0.number == fragment.canonicalLine })?.text ?? fragment.text
        return DocumentPaginationAtom(
            groupID: "\(fragment.readingUnitID)|\(fragment.blockID)",
            startLocation: start,
            endLocation: start + max(1, (text as NSString).length),
            role: fragment.role,
            evidence: DocumentPaginationLaw.evidence(
                for: fragment.canonicalLine,
                in: block
            ),
            isEmpty: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
    }

    private func hasText(_ fragment: PageTextFragment) -> Bool {
        !fragment.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
