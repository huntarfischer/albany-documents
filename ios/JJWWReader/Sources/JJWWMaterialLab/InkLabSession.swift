import Foundation
import JJWWTypography

#if DEBUG
@MainActor
public final class InkLabSession: ObservableObject {
    @Published public private(set) var profiles: [InkAwakeningProfile]
    @Published public var selectedProfileID: String
    @Published public var draftProfile: InkAwakeningProfile
    @Published public var seed: UInt64
    @Published public var previewProgress: Double
    @Published public var transferText: String
    @Published public private(set) var message: String?

    public init(
        profiles: [InkAwakeningProfile] = InkAwakeningCatalog.all,
        seed: UInt64 = 1827
    ) {
        precondition(!profiles.isEmpty)
        self.profiles = profiles
        self.selectedProfileID = profiles[0].id
        self.draftProfile = profiles[0]
        self.seed = seed
        self.previewProgress = 0.58
        self.transferText = ""
    }

    public func selectProfile(id: String) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }
        selectedProfileID = id
        draftProfile = profile
        message = nil
    }

    public func update(_ mutation: (inout InkAwakeningProfile) -> Void) {
        mutation(&draftProfile)
        message = "Draft changed"
    }

    @discardableResult
    public func exportProfile() throws -> String {
        let payload = InkLabTransfer(formatVersion: "0.3-ink-profile", profile: draftProfile)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        let text = String(decoding: data, as: UTF8.self)
        transferText = text
        message = "Exported \(draftProfile.id)"
        return text
    }

    public func importProfile() throws {
        let data = Data(transferText.utf8)
        let payload = try JSONDecoder().decode(InkLabTransfer.self, from: data)
        guard payload.formatVersion == "0.3-ink-profile" else {
            throw InkLabError.unsupportedFormat(payload.formatVersion)
        }
        draftProfile = payload.profile
        selectedProfileID = payload.profile.id
        message = "Imported \(payload.profile.id)"
    }
}

public enum InkLabError: Error, Equatable {
    case unsupportedFormat(String)
}

private struct InkLabTransfer: Codable {
    let formatVersion: String
    let profile: InkAwakeningProfile
}
#endif
