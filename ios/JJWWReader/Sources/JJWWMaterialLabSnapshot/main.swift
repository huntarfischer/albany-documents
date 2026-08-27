import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import JJWWMaterials
import JJWWMaterialLab

#if DEBUG
@main
enum JJWWMaterialLabSnapshot {
    @MainActor
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            let outputURL = outputURL(from: arguments)
            let exportDirectory = exportDirectoryURL(from: arguments)
            let store = try MaterialProfileStore.bundled()

            let lab = MaterialLabView(profiles: store.profiles)
                .frame(width: 1600, height: 1100)

            let renderer = ImageRenderer(content: lab)
            renderer.proposedSize = ProposedViewSize(width: 1600, height: 1100)
            renderer.scale = 1

            guard let cgImage = renderer.cgImage else {
                throw SnapshotError.renderFailed
            }

            try FileManager.default.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try writePNG(cgImage, to: outputURL)

            if let exportDirectory {
                try FileManager.default.createDirectory(
                    at: exportDirectory,
                    withIntermediateDirectories: true
                )
                for profile in store.profiles {
                    var export = profile
                    export.version = "0.2"
                    let text = try MaterialProfileCodec.export(profile: export)
                    let url = exportDirectory.appendingPathComponent("\(profile.id)-material-profile-v0.2.json")
                    try text.write(to: url, atomically: true, encoding: .utf8)
                }
            }

            print("Wrote Stage 2 Material Lab snapshot to \(outputURL.path)")
        } catch {
            fputs("Material Lab snapshot failed: \(error)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }

    private static func outputURL(from arguments: [String]) -> URL {
        guard let index = arguments.firstIndex(of: "--output"), arguments.indices.contains(index + 1) else {
            return URL(fileURLWithPath: "/tmp/jjww-material-lab-stage2.png")
        }
        return URL(fileURLWithPath: arguments[index + 1])
    }

    private static func exportDirectoryURL(from arguments: [String]) -> URL? {
        guard let index = arguments.firstIndex(of: "--export-dir"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
    }

    private static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw SnapshotError.destinationFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw SnapshotError.writeFailed
        }
    }
}
#else
@main
enum JJWWMaterialLabSnapshot {
    static func main() {
        print("JJWW Material Lab is DEBUG-only.")
    }
}
#endif

private enum SnapshotError: Error {
    case renderFailed
    case destinationFailed
    case writeFailed
}
