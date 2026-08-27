import SwiftUI
import JJWWReaderCore

public enum TypographyRole: String, Codable, CaseIterable, Sendable {
    case dateHeading
    case sourceHeader
    case sectionTitle
    case body
    case firstPersonBody
    case witnessLabel
    case counselLabel
    case courtLabel
    case verse
    case editorialCutPaper
}

public enum TypographyDynamicTextStyle: String, Codable, Sendable {
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote

    var swiftUIStyle: Font.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        }
    }
}

public enum TypographyDesign: String, Codable, Sendable {
    case serif
    case rounded
    case monospaced
    case system

    var swiftUIDesign: Font.Design {
        switch self {
        case .serif: return .serif
        case .rounded: return .rounded
        case .monospaced: return .monospaced
        case .system: return .default
        }
    }
}

public enum TypographyWeight: String, Codable, Sendable {
    case regular
    case medium
    case semibold
    case bold
    case black

    var swiftUIWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .black: return .black
        }
    }
}

public struct TypographyToken: Codable, Equatable, Sendable {
    public let role: TypographyRole
    public let textStyle: TypographyDynamicTextStyle
    public let design: TypographyDesign
    public let weight: TypographyWeight
    public let tracking: Double
    public let lineSpacing: Double
    public let uppercase: Bool
    public let centered: Bool

    public init(
        role: TypographyRole,
        textStyle: TypographyDynamicTextStyle,
        design: TypographyDesign,
        weight: TypographyWeight,
        tracking: Double = 0,
        lineSpacing: Double = 0,
        uppercase: Bool = false,
        centered: Bool = false
    ) {
        self.role = role
        self.textStyle = textStyle
        self.design = design
        self.weight = weight
        self.tracking = tracking
        self.lineSpacing = lineSpacing
        self.uppercase = uppercase
        self.centered = centered
    }

    public var font: Font {
        .system(textStyle.swiftUIStyle, design: design.swiftUIDesign, weight: weight.swiftUIWeight)
    }
}

public struct TypographyProfileDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let tokens: [TypographyToken]

    public init(id: String, displayName: String, tokens: [TypographyToken]) {
        self.id = id
        self.displayName = displayName
        self.tokens = tokens
    }

    public func token(_ role: TypographyRole) -> TypographyToken {
        tokens.first(where: { $0.role == role })
            ?? TypographyCatalog.fallbackToken(role)
    }
}

public enum TypographyCatalog {
    public static let editorial = TypographyProfileDefinition(
        id: TypographyProfile.jjwwEditorial.id,
        displayName: "JJWW Editorial",
        tokens: [
            token(.dateHeading, .title2, .serif, .black, tracking: 1.8, uppercase: true),
            token(.sourceHeader, .title, .serif, .black, tracking: 0.8, uppercase: true),
            token(.sectionTitle, .largeTitle, .serif, .black, tracking: 0.6, uppercase: true),
            token(.body, .body, .serif, .regular, lineSpacing: 4),
            token(.editorialCutPaper, .title3, .serif, .black, tracking: 1.1, uppercase: true)
        ]
    )

    public static let newspaper = TypographyProfileDefinition(
        id: TypographyProfile.newspaper1827.id,
        displayName: "Newspaper 1827",
        tokens: [
            token(.dateHeading, .title3, .serif, .bold, tracking: 1.2, uppercase: true, centered: true),
            token(.sourceHeader, .title2, .serif, .black, tracking: 0.6, uppercase: true, centered: true),
            token(.sectionTitle, .headline, .serif, .black, tracking: 0.8, uppercase: true, centered: true),
            token(.body, .body, .serif, .regular, lineSpacing: 2)
        ]
    )

    public static let confession = TypographyProfileDefinition(
        id: TypographyProfile.confessionPamphlet1827.id,
        displayName: "Confession Pamphlet 1827",
        tokens: [
            token(.dateHeading, .title3, .serif, .semibold, tracking: 0.8, centered: true),
            token(.sourceHeader, .title2, .serif, .black, tracking: 0.5, uppercase: true, centered: true),
            token(.sectionTitle, .title, .serif, .black, tracking: 0.7, uppercase: true, centered: true),
            token(.body, .body, .serif, .regular, lineSpacing: 5),
            token(.firstPersonBody, .body, .serif, .regular, lineSpacing: 6)
        ]
    )

    public static let trial = TypographyProfileDefinition(
        id: TypographyProfile.trialRecord1827.id,
        displayName: "Trial Record 1827",
        tokens: [
            token(.dateHeading, .title3, .serif, .semibold, tracking: 0.8),
            token(.sourceHeader, .title2, .serif, .black, tracking: 0.5, uppercase: true),
            token(.sectionTitle, .title, .serif, .black, tracking: 0.6, uppercase: true),
            token(.body, .body, .serif, .regular, lineSpacing: 3),
            token(.witnessLabel, .headline, .serif, .bold, tracking: 0.5),
            token(.counselLabel, .subheadline, .serif, .semibold, tracking: 0.4),
            token(.courtLabel, .headline, .serif, .black, tracking: 0.8, uppercase: true)
        ]
    )

    public static let farewell = TypographyProfileDefinition(
        id: TypographyProfile.farewell1827.id,
        displayName: "Farewell Address 1827",
        tokens: [
            token(.dateHeading, .subheadline, .serif, .medium, tracking: 0.8, centered: true),
            token(.sourceHeader, .title3, .serif, .semibold, tracking: 0.6, centered: true),
            token(.sectionTitle, .title, .serif, .black, tracking: 1.0, uppercase: true, centered: true),
            token(.verse, .body, .serif, .regular, lineSpacing: 9, centered: true),
            token(.body, .body, .serif, .regular, lineSpacing: 7)
        ]
    )

    public static let all: [TypographyProfileDefinition] = [editorial, newspaper, confession, trial, farewell]

    public static func profile(id: String) -> TypographyProfileDefinition? {
        all.first { $0.id == id }
    }

    static func fallbackToken(_ role: TypographyRole) -> TypographyToken {
        token(role, .body, .serif, .regular, lineSpacing: 3)
    }

    private static func token(
        _ role: TypographyRole,
        _ textStyle: TypographyDynamicTextStyle,
        _ design: TypographyDesign,
        _ weight: TypographyWeight,
        tracking: Double = 0,
        lineSpacing: Double = 0,
        uppercase: Bool = false,
        centered: Bool = false
    ) -> TypographyToken {
        TypographyToken(
            role: role,
            textStyle: textStyle,
            design: design,
            weight: weight,
            tracking: tracking,
            lineSpacing: lineSpacing,
            uppercase: uppercase,
            centered: centered
        )
    }
}

public struct TypographicText: View {
    private let text: String
    private let token: TypographyToken

    public init(_ text: String, token: TypographyToken) {
        self.text = text
        self.token = token
    }

    public var body: some View {
        Text(token.uppercase ? text.uppercased() : text)
            .font(token.font)
            .fontWeight(token.weight.swiftUIWeight)
            .tracking(token.tracking)
            .lineSpacing(token.lineSpacing)
            .multilineTextAlignment(token.centered ? .center : .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(Text(text))
    }
}
