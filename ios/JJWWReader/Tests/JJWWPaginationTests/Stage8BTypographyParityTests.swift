import Foundation
import Testing
import JJWWReaderCore
import JJWWTypography
import JJWWScrollReader
@testable import JJWWPagination

@Suite("JJWW Stage 8B Typographic Parity")
struct Stage8BTypographyParityTests {
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

    @Test("B0 freezes the accepted Layer 1 semantic baseline before typography moves")
    func semanticBaselineRemainsSealed() throws {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let semantics = try Stage8Layer1Semantics.load(ownership: ownership)
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)

        #expect(
            edition.canonicalLineSequenceSHA256 ==
            "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e"
        )
        #expect(ownership.lines.count == 2069)
        #expect(ownership.containers.count == 82)
        #expect(edition.orderedReadingUnits.count == 75)
        #expect(semantics.structuralSpans.count == 468)
        #expect(semantics.sourceOccurrences.count == 82)
        #expect(semantics.sourceContexts.count == 44)

        #expect(try role(at: 26, in: edition) == .sectionTitle)
        #expect(try role(at: 38, in: edition) == .sourceHeader)
        #expect(try role(at: 42, in: edition) == .sourceHeader)
        #expect(try role(at: 284, in: edition) == .witnessLabel)
        #expect(try role(at: 924, in: edition) == .counselLabel)
    }

    @Test("B2 resolves the actual Argus font, scale, tracking, leading and paragraph geometry once")
    func argusGeometryIsResolvedOnce() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let unit = try unit(containing: 24, in: edition)

        let date = try #require(
            PageTypographyResolver.resolve(
                text: try line(24, in: edition).text,
                canonicalLine: 24,
                role: .dateHeading,
                unit: unit,
                textScale: .standard,
                isOpeningHeader: true,
                isFirstOpeningHeader: true,
                isLastOpeningHeader: false
            )
        )
        let source = try #require(
            PageTypographyResolver.resolve(
                text: try line(25, in: edition).text,
                canonicalLine: 25,
                role: .sourceHeader,
                unit: unit,
                textScale: .standard,
                isOpeningHeader: true,
                isFirstOpeningHeader: false,
                isLastOpeningHeader: false
            )
        )
        let headline = try #require(
            PageTypographyResolver.resolve(
                text: try line(26, in: edition).text,
                canonicalLine: 26,
                role: .sectionTitle,
                unit: unit,
                textScale: .standard,
                isOpeningHeader: true,
                isFirstOpeningHeader: false,
                isLastOpeningHeader: false
            )
        )
        let body = try #require(
            PageTypographyResolver.resolve(
                text: try line(27, in: edition).text,
                canonicalLine: 27,
                role: .body,
                unit: unit,
                textScale: .standard,
                isOpeningHeader: false,
                isFirstOpeningHeader: false,
                isLastOpeningHeader: false
            )
        )

        #expect(date.token.fontFamily == "Baskerville")
        #expect(abs(date.pointSize - 13.056) < 0.001)
        #expect(date.paragraphSpacingBefore == 8)

        #expect(source.token.fontFamily == "Bodoni 72")
        #expect(abs(source.pointSize - 28.16) < 0.001)
        #expect(abs(source.tracking - (-0.25)) < 0.001)
        #expect(source.lineSpacing == -1.5)
        #expect(source.displayText.contains("\n"))
        #expect(
            (source.displayText as NSString).length ==
            (try line(25, in: edition).text as NSString).length
        )

        #expect(headline.token.fontFamily == "Baskerville")
        #expect(abs(headline.pointSize - 19.1488) < 0.001)
        #expect(abs(headline.tracking - 0.20) < 0.001)

        #expect(body.token.fontFamily == "Baskerville")
        #expect(body.pointSize == 17)
        #expect(abs(body.lineSpacing - 1.10) < 0.001)
        #expect(body.firstLineHeadIndent == 12)
        #expect(body.paragraphSpacingAfter == 1.5)
    }

    @Test("B3/B4 pagination carries every input required to reproduce the measured page typography")
    @MainActor
    func paginationCarriesSharedPhysicalContract() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let result = try PaginationEngine().paginate(edition: edition)

        #expect(!result.pages.isEmpty)
        #expect(
            result.pages.allSatisfy {
                $0.textScale == .standard &&
                $0.pageWidth == PageGeometry.phonePortrait.width &&
                abs(
                    $0.contentWidth -
                    ($0.pageWidth - $0.resolvedMargins.leading - $0.resolvedMargins.trailing)
                ) < 0.001
            }
        )

        let sourceFragment = try #require(
            result.pages
                .flatMap(\.fragments)
                .first {
                    $0.canonicalLine == 25 &&
                    $0.role == .sourceHeader
                }
        )
        #expect(sourceFragment.isOpeningHeader)

        let sourceUnit = try #require(edition.readingUnit(id: sourceFragment.readingUnitID))
        let resolved = try #require(
            PageTypographyResolver.resolve(
                text: sourceFragment.text,
                canonicalLine: sourceFragment.canonicalLine,
                role: sourceFragment.role,
                unit: sourceUnit,
                textScale: result.pages.first(where: { $0.fragments.contains(sourceFragment) })?.textScale ?? .standard,
                isOpeningHeader: sourceFragment.isOpeningHeader,
                isFirstOpeningHeader: sourceFragment.isFirstOpeningHeader,
                isLastOpeningHeader: sourceFragment.isLastOpeningHeader
            )
        )
        #expect(resolved.token.fontFamily == "Bodoni 72")
        #expect(abs(resolved.pointSize - 28.16) < 0.001)

        for unit in edition.orderedReadingUnits {
            #expect(
                result.reconstructedCanonicalText(for: unit.id) ==
                unit.canonicalText
            )
        }
    }

    @Test("B4 render fragments do not reapply paragraph-edge geometry at a physical page split")
    func fragmentRenderingSuppressesInteriorParagraphEdges() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let unit = try unit(containing: 27, in: edition)
        let body = try #require(
            PageTypographyResolver.resolve(
                text: try line(27, in: edition).text,
                canonicalLine: 27,
                role: .body,
                unit: unit,
                textScale: .standard,
                isOpeningHeader: false,
                isFirstOpeningHeader: false,
                isLastOpeningHeader: false
            )
        )

        let middle = body.renderingFragment(
            startsCanonicalLine: false,
            endsCanonicalLine: false
        )
        #expect(middle.paragraphSpacingBefore == 0)
        #expect(middle.paragraphSpacingAfter == 0)
        #expect(middle.followingDecorationHeight == 0)
        #expect(middle.firstLineHeadIndent == 0)

        let ending = body.renderingFragment(
            startsCanonicalLine: false,
            endsCanonicalLine: true
        )
        #expect(ending.paragraphSpacingBefore == 0)
        #expect(ending.paragraphSpacingAfter == body.paragraphSpacingAfter)
        #expect(ending.firstLineHeadIndent == 0)
    }

    @Test("B5 nonstandard page geometry and text scale survive into every rendered leaf contract")
    @MainActor
    func nonstandardScaleAndWidthAreNotLostAfterMeasurement() throws {
        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let geometry = PageGeometry(
            width: 428,
            height: 926,
            margins: PageMargins(
                top: 58,
                leading: 38,
                bottom: 60,
                trailing: 38
            )
        )
        let result = try PaginationEngine().paginate(
            edition: edition,
            configuration: PaginationConfiguration(
                geometry: geometry,
                textScale: .large,
                marginProfileVersion: "stage8b-large-width"
            )
        )

        #expect(!result.pages.isEmpty)
        #expect(
            result.pages.allSatisfy {
                $0.textScale == .large &&
                $0.pageWidth == 428
            }
        )
        #expect(
            result.pages.allSatisfy {
                abs(
                    $0.contentWidth -
                    (428 - $0.resolvedMargins.leading - $0.resolvedMargins.trailing)
                ) < 0.001
            }
        )
    }

    private func unit(
        containing canonicalLine: Int,
        in edition: Edition
    ) throws -> ReadingUnit {
        try #require(
            edition.orderedReadingUnits.first {
                $0.canonicalAnchor.contains(line: canonicalLine)
            }
        )
    }

    private func line(
        _ canonicalLine: Int,
        in edition: Edition
    ) throws -> CanonicalLine {
        try #require(
            edition.orderedReadingUnits
                .flatMap(\.blocks)
                .flatMap(\.lines)
                .first { $0.number == canonicalLine }
        )
    }

    private func role(
        at canonicalLine: Int,
        in edition: Edition
    ) throws -> TypographyRole {
        let unit = try unit(containing: canonicalLine, in: edition)
        let block = try #require(
            unit.blocks.first {
                $0.canonicalAnchor.contains(line: canonicalLine)
            }
        )
        return try #require(
            ReaderLineRoleResolver
                .presentations(for: block, in: unit)
                .first {
                    $0.canonicalLine.number == canonicalLine
                }
        ).role
    }
}
