import Foundation
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

public enum TypographyDynamicTextStyle: String, Codable, CaseIterable, Sendable {
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

public enum TypographyDesign: String, Codable, CaseIterable, Sendable {
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

public enum TypographyWeight: String, Codable, CaseIterable, Sendable {
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

public enum TypographyParagraphAlignment: String, Codable, CaseIterable, Sendable {
    case leading
    case centered
    case justified
}

public struct TypographyToken: Codable, Equatable, Sendable {
    public var role: TypographyRole
    public var textStyle: TypographyDynamicTextStyle
    public var design: TypographyDesign
    public var weight: TypographyWeight
    public var tracking: Double
    public var lineSpacing: Double
    public var uppercase: Bool
    public var paragraphAlignment: TypographyParagraphAlignment
    public var hyphenationFactor: Double
    public var fontFamily: String?

    public init(
        role: TypographyRole,
        textStyle: TypographyDynamicTextStyle,
        design: TypographyDesign,
        weight: TypographyWeight,
        tracking: Double = 0,
        lineSpacing: Double = 0,
        uppercase: Bool = false,
        centered: Bool = false,
        paragraphAlignment: TypographyParagraphAlignment? = nil,
        hyphenationFactor: Double = 0,
        fontFamily: String? = nil
    ) {
        self.role = role
        self.textStyle = textStyle
        self.design = design
        self.weight = weight
        self.tracking = tracking
        self.lineSpacing = lineSpacing
        self.uppercase = uppercase
        self.paragraphAlignment = paragraphAlignment ?? (centered ? .centered : .leading)
        self.hyphenationFactor = min(1, max(0, hyphenationFactor))
        self.fontFamily = fontFamily
    }

    public var centered: Bool { paragraphAlignment == .centered }
    public var justified: Bool { paragraphAlignment == .justified }

    public var font: Font {
        if let fontFamily {
            return .custom(
                fontFamily,
                size: typographyBasePointSize(for: textStyle),
                relativeTo: textStyle.swiftUIStyle
            )
            .weight(weight.swiftUIWeight)
        }
        return .system(textStyle.swiftUIStyle, design: design.swiftUIDesign, weight: weight.swiftUIWeight)
    }
}

public struct TypographyProfileDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var displayName: String
    public var tokens: [TypographyToken]

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

/// Debug-time typography overrides used by the Stage 7.75 Reader Workshop.
/// Production remains entirely catalog-driven when no override is installed.
public final class TypographyTuningRegistry: @unchecked Sendable {
    public static let shared = TypographyTuningRegistry()

    private let lock = NSLock()
    private var overrides: [String: TypographyProfileDefinition] = [:]

    private init() {}

    public func profile(id: String) -> TypographyProfileDefinition? {
        lock.lock()
        defer { lock.unlock() }
        return overrides[id]
    }

    public func set(_ profile: TypographyProfileDefinition) {
        lock.lock()
        overrides[profile.id] = profile
        lock.unlock()
    }

    public func remove(id: String) {
        lock.lock()
        overrides.removeValue(forKey: id)
        lock.unlock()
    }

    public func removeAll() {
        lock.lock()
        overrides.removeAll()
        lock.unlock()
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
            token(.dateHeading, .subheadline, .serif, .bold, tracking: 0.95, uppercase: true, centered: true, fontFamily: "Baskerville"),
            token(.sourceHeader, .title2, .serif, .black, tracking: -0.50, uppercase: true, centered: true, fontFamily: "Bodoni 72"),
            token(.sectionTitle, .headline, .serif, .bold, tracking: 0.20, uppercase: true, centered: true, fontFamily: "Baskerville"),
            token(
                .body,
                .body,
                .serif,
                .regular,
                lineSpacing: 1,
                paragraphAlignment: .justified,
                hyphenationFactor: 0.74,
                fontFamily: "Baskerville"
            )
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

    /// Broadside-inspired, but still semantic live text. The surviving artifact's
    /// two columns are presented serially on phone; verse therefore remains a
    /// single leading-aligned reading measure rather than being centered.
    public static let farewell = TypographyProfileDefinition(
        id: TypographyProfile.farewell1827.id,
        displayName: "Farewell Address 1827",
        tokens: [
            token(.dateHeading, .footnote, .serif, .medium, tracking: 0.45, centered: true),
            token(.sourceHeader, .subheadline, .serif, .semibold, tracking: 0.7, centered: true),
            token(.sectionTitle, .largeTitle, .serif, .black, tracking: 1.15, uppercase: true, centered: true),
            token(.verse, .body, .serif, .regular, lineSpacing: 4, paragraphAlignment: .leading),
            token(.body, .body, .serif, .regular, lineSpacing: 5)
        ]
    )

    public static let all: [TypographyProfileDefinition] = [
        editorial,
        newspaper,
        newspaper1905,
        newspaper1967,
        confession,
        publishedAccount,
        trial,
        officialDocument,
        historicalBook,
        correspondence,
        displayArtifact,
        farewell,
        referenceBackMatter
    ]

    public static func bundledProfile(id: String) -> TypographyProfileDefinition? {
        all.first { $0.id == id }
    }

    public static func profile(id: String) -> TypographyProfileDefinition? {
        TypographyTuningRegistry.shared.profile(id: id) ?? bundledProfile(id: id)
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
        centered: Bool = false,
        paragraphAlignment: TypographyParagraphAlignment? = nil,
        hyphenationFactor: Double = 0,
        fontFamily: String? = nil
    ) -> TypographyToken {
        TypographyToken(
            role: role,
            textStyle: textStyle,
            design: design,
            weight: weight,
            tracking: tracking,
            lineSpacing: lineSpacing,
            uppercase: uppercase,
            centered: centered,
            paragraphAlignment: paragraphAlignment,
            hyphenationFactor: hyphenationFactor,
            fontFamily: fontFamily
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

    @ViewBuilder
    public var body: some View {
        if token.justified {
            JustifiedTypographicText(text, token: token)
                .accessibilityLabel(Text(text))
        } else {
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
}

private func typographyBasePointSize(for style: TypographyDynamicTextStyle) -> CGFloat {
    switch style {
    case .largeTitle: return 34
    case .title: return 28
    case .title2: return 22
    case .title3: return 20
    case .headline: return 17
    case .body: return 17
    case .callout: return 16
    case .subheadline: return 15
    case .footnote: return 13
    }
}
