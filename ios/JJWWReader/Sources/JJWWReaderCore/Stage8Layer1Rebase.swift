import Foundation

public struct Stage8Layer0Seal: Codable, Equatable, Sendable {
    public let version: String
    public let lineCount: Int
    public let lineSequenceSHA256: String
}

public struct Stage8Layer1ContainerCorrection: Codable, Equatable, Sendable {
    public let containerID: String
    public let lineStart: Int
    public let lineEnd: Int
    public let oldLabel: String
    public let newLabel: String
    public let oldTextSHA256: String
    public let newTextSHA256: String
}

public struct Stage8Layer1RebaseSeal: Codable, Equatable, Sendable {
    public let formatVersion: String
    public let sourceLayer0: Stage8Layer0Seal
    public let targetLayer0: Stage8Layer0Seal
    public let geometryUnchanged: Bool
    public let expectedContainerCount: Int
    public let expectedStructuralUnitCount: Int
    public let expectedSourceCount: Int
    public let expectedSourceOccurrenceCount: Int
    public let expectedSourceContextCount: Int
    public let containerCorrections: [Stage8Layer1ContainerCorrection]

    public static func bundled() throws -> Stage8Layer1RebaseSeal {
        guard let url = Bundle.module.url(
            forResource: "stage8-layer1-v1.1-rebase-v1",
            withExtension: "json"
        ) else {
            throw Stage8Layer1RebaseError.sealMissing
        }

        return try JSONDecoder().decode(
            Stage8Layer1RebaseSeal.self,
            from: Data(contentsOf: url)
        )
    }
}

public enum Stage8Layer1RebaseError: Error, Equatable, CustomStringConvertible {
    case sealMissing

    public var description: String {
        switch self {
        case .sealMissing:
            return "Stage 8 Layer 1 v1.1 rebase seal is missing."
        }
    }
}
