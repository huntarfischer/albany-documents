import Foundation
import Testing
import JJWWReaderCore
@testable import JJWWPagination

@Suite("JJWW Stage 8C Act II Applied Documentary Pagination")
struct Stage8CAct2PaginationTests {
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

    @Test("Act II the early May newspaper openings carry body matter with their documentary headers")
    @MainActor
    func earlyNewspaperOpeningsAreNotOrphaned() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        try expectOpening(startLine: 24, bodyLine: 27, in: result)
        try expectOpening(startLine: 37, bodyLine: 40, in: result)
        try expectOpening(startLine: 41, bodyLine: 43, in: result)
        try expectOpening(startLine: 44, bodyLine: 46, in: result)
    }

    @Test("Act II does not strand the enclosing pamphlet source before its nested request document")
    @MainActor
    func nestedRequestOpeningIsNotSplitAtSourceHeader() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        for pair in zip(result.pages, result.pages.dropFirst()) {
            guard let last = pair.0.fragments.last(where: hasText),
                  let first = pair.1.fragments.first(where: hasText) else {
                continue
            }
            #expect(!(last.canonicalLine == 1_173 && first.canonicalLine == 1_174))
        }

        let requestPage = try #require(
            result.pages.first { page in
                page.fragments.contains {
                    $0.canonicalLine == 1_174 && $0.utf16Start == 0
                }
            }
        )
        #expect(
            requestPage.fragments.contains {
                $0.canonicalLine == 1_175 && hasText($0)
            }
        )
    }

    @Test("Act II still reconstructs every production ReadingUnit exactly")
    @MainActor
    func canonicalReconstructionRemainsExact() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        #expect(edition.canonicalLineSequenceSHA256 == "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e")
        #expect(edition.orderedReadingUnits.count == 75)
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).count == 82)
        #expect(edition.orderedReadingUnits.flatMap(\.blocks).flatMap(\.lines).count == 2_069)
        #expect(!result.pages.isEmpty)
        #expect(result.pages.allSatisfy { !$0.fragments.isEmpty })

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

    private func expectOpening(
        startLine: Int,
        bodyLine: Int,
        in result: PaginationResult
    ) throws {
        let page = try #require(
            result.pages.first { page in
                page.fragments.contains {
                    $0.canonicalLine == startLine && $0.utf16Start == 0
                }
            }
        )
        #expect(
            page.fragments.contains {
                $0.canonicalLine == bodyLine && hasText($0)
            }
        )
    }

    private func hasText(_ fragment: PageTextFragment) -> Bool {
        !fragment.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
