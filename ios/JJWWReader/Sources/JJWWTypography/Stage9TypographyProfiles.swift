import Foundation
import JJWWReaderCore

/// Book 1.0 typography identities for the Stage 9 documentary families that
/// previously borrowed one of the five prototype profiles. Starting values are
/// deliberately transplanted from the proven profile they used before this pass;
/// independence comes first, art-direction changes remain Workshop decisions.
public extension TypographyCatalog {
    static let newspaper1905 = TypographyProfileDefinition(
        id: "newspaper1905",
        displayName: "Newspaper 1905",
        tokens: newspaper.tokens
    )

    static let newspaper1967 = TypographyProfileDefinition(
        id: "newspaper1967",
        displayName: "Newspaper 1967",
        tokens: newspaper.tokens
    )

    static let publishedAccount = TypographyProfileDefinition(
        id: "publishedAccountPamphlet",
        displayName: "Published Account Pamphlet",
        tokens: confession.tokens
    )

    static let officialDocument = TypographyProfileDefinition(
        id: "officialDocument",
        displayName: "Official Document",
        tokens: trial.tokens
    )

    static let historicalBook = TypographyProfileDefinition(
        id: "historicalBook",
        displayName: "Historical Book Excerpt",
        tokens: editorial.tokens
    )

    static let correspondence = TypographyProfileDefinition(
        id: "correspondence",
        displayName: "Correspondence",
        tokens: editorial.tokens
    )

    static let displayArtifact = TypographyProfileDefinition(
        id: "displayArtifact",
        displayName: "Display Artifact · Verse / Broadside",
        tokens: farewell.tokens
    )

    static let referenceBackMatter = TypographyProfileDefinition(
        id: "referenceBackMatter",
        displayName: "Reference / Back Matter",
        tokens: editorial.tokens
    )
}
