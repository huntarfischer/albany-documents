import Foundation

public struct MaterialProfileDocument: Codable, Equatable, Sendable {
    public let formatVersion: String
    public let profile: MaterialProfileDefinition

    public init(
        formatVersion: String = MaterialProfileCodec.currentFormatVersion,
        profile: MaterialProfileDefinition
    ) {
        self.formatVersion = formatVersion
        self.profile = profile
    }
}

public enum MaterialProfileCodecError: Error, Equatable {
    case invalidUTF8
    case unsupportedFormatVersion(String)
}

public enum MaterialProfileCodec {
    public static let currentFormatVersion = "0.2-material-profile"

    public static func export(profile: MaterialProfileDefinition) throws -> String {
        let document = MaterialProfileDocument(profile: profile)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(document)
        guard let text = String(data: data, encoding: .utf8) else {
            throw MaterialProfileCodecError.invalidUTF8
        }
        return text + "\n"
    }

    public static func importProfile(from text: String) throws -> MaterialProfileDefinition {
        guard let data = text.data(using: .utf8) else {
            throw MaterialProfileCodecError.invalidUTF8
        }
        let document = try JSONDecoder().decode(MaterialProfileDocument.self, from: data)
        guard document.formatVersion == currentFormatVersion else {
            throw MaterialProfileCodecError.unsupportedFormatVersion(document.formatVersion)
        }
        return document.profile
    }
}
