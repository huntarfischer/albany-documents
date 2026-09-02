import XCTest
@testable import JJWWTypography

final class Stage3TypographyTests: XCTestCase {
    func testBookOneTypographyProfilesExist() {
        XCTAssertEqual(
            Set(TypographyCatalog.all.map(\.id)),
            Set([
                "jjwwEditorial",
                "newspaper1827",
                "newspaper1905",
                "newspaper1967",
                "confessionPamphlet1827",
                "publishedAccountPamphlet",
                "trialRecord1827",
                "officialDocument",
                "historicalBook",
                "correspondence",
                "displayArtifact",
                "farewell1827",
                "referenceBackMatter"
            ])
        )
    }

    func testInkProfilesCoverFivePrototypeSections() {
        XCTAssertEqual(
            Set(InkAwakeningCatalog.all.map(\.id)),
            Set([
                "ink.argus1827",
                "ink.dailyAdvertiser1827",
                "ink.confession1827",
                "ink.trial1827",
                "ink.farewell1827"
            ])
        )
    }

    func testTypographyUsesSemanticDynamicTypeStyles() {
        for profile in TypographyCatalog.all {
            XCTAssertFalse(profile.tokens.isEmpty)
            for token in profile.tokens {
                XCTAssertFalse(token.textStyle.rawValue.isEmpty)
            }
        }
    }

    func testNewspaperBodyIsFullyJustifiedAndHyphenated() {
        let body = TypographyCatalog.newspaper.token(.body)
        XCTAssertEqual(body.paragraphAlignment, .justified)
        XCTAssertGreaterThan(body.hyphenationFactor, 0.5)

        XCTAssertNotEqual(TypographyCatalog.confession.token(.body).paragraphAlignment, .justified)
        XCTAssertNotEqual(TypographyCatalog.trial.token(.body).paragraphAlignment, .justified)
        XCTAssertNotEqual(TypographyCatalog.farewell.token(.body).paragraphAlignment, .justified)
    }

    func testReduceMotionUsesShortFadeAtNaturalEntry() {
        XCTAssertEqual(
            InkAwakeningPolicy.behavior(
                entryContext: .naturalSectionEntry,
                reduceMotion: true,
                explicitlyInstant: false
            ),
            .shortFade
        )
    }

    func testJumpAndSearchResolveImmediately() {
        XCTAssertEqual(
            InkAwakeningPolicy.behavior(
                entryContext: .jumpIntoSection,
                reduceMotion: false,
                explicitlyInstant: false
            ),
            .instant
        )
        XCTAssertEqual(
            InkAwakeningPolicy.behavior(
                entryContext: .searchResult,
                reduceMotion: false,
                explicitlyInstant: false
            ),
            .instant
        )
    }

    func testNaturalEntryAnimatesWhenMotionAllowed() {
        XCTAssertEqual(
            InkAwakeningPolicy.behavior(
                entryContext: .naturalSectionEntry,
                reduceMotion: false,
                explicitlyInstant: false
            ),
            .animated
        )
    }

    func testInkProfilesRoundTripWithoutChangingParameters() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for profile in InkAwakeningCatalog.all {
            let data = try encoder.encode(profile)
            let decoded = try decoder.decode(InkAwakeningProfile.self, from: data)
            XCTAssertEqual(decoded, profile)
        }
    }

    func testFarewellRitualIsQuietestAndSlowestOfPrototype() {
        XCTAssertGreaterThan(InkAwakeningCatalog.farewell.duration, InkAwakeningCatalog.trial.duration)
        XCTAssertLessThan(InkAwakeningCatalog.farewell.irregularity, InkAwakeningCatalog.argus.irregularity)
    }
}
