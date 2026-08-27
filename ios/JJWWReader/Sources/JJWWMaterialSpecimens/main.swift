import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import JJWWMaterials

@main
enum JJWWMaterialSpecimens {
    @MainActor
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            let state = try parseState(arguments)
            let outputURL = try parseOutput(arguments)
            let store = try MaterialProfileStore.bundled()

            let sheet = MaterialSpecimenSheet(
                profiles: store.profiles,
                state: state
            )
            .frame(width: 1120, height: 1120)

            let renderer = ImageRenderer(content: sheet)
            renderer.proposedSize = ProposedViewSize(width: 1120, height: 1120)
            renderer.scale = 2

            guard let cgImage = renderer.cgImage else {
                throw SpecimenError.renderFailed
            }

            try FileManager.default.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            guard let destination = CGImageDestinationCreateWithURL(
                outputURL as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else {
                throw SpecimenError.destinationFailed
            }

            CGImageDestinationAddImage(destination, cgImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw SpecimenError.writeFailed
            }

            print("Wrote \(state.rawValue) material specimen sheet to \(outputURL.path)")
        } catch {
            fputs("Material specimen generation failed: \(error)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }

    private static func parseState(_ arguments: [String]) throws -> MaterialState {
        guard let index = arguments.firstIndex(of: "--state"), arguments.indices.contains(index + 1) else {
            return .full
        }
        guard let state = MaterialState(rawValue: arguments[index + 1]) else {
            throw SpecimenError.invalidState(arguments[index + 1])
        }
        return state
    }

    private static func parseOutput(_ arguments: [String]) throws -> URL {
        guard let index = arguments.firstIndex(of: "--output"), arguments.indices.contains(index + 1) else {
            return URL(fileURLWithPath: "/tmp/jjww-material-specimen-full.png")
        }
        return URL(fileURLWithPath: arguments[index + 1])
    }
}

private enum SpecimenError: Error, CustomStringConvertible {
    case invalidState(String)
    case renderFailed
    case destinationFailed
    case writeFailed

    var description: String {
        switch self {
        case let .invalidState(value): return "invalid material state '\(value)'"
        case .renderFailed: return "ImageRenderer did not produce a CGImage"
        case .destinationFailed: return "could not create PNG destination"
        case .writeFailed: return "could not finalize PNG"
        }
    }
}
