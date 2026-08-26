import Foundation
import JJWWReaderCore

let canonicalPath = CommandLine.arguments.dropFirst().first
    ?? "../../jesse-james-and-the-widow-whipple-canonical.json"

do {
    let canonicalURL = URL(fileURLWithPath: canonicalPath)
    let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)

    print("\(edition.title) | \(edition.version)")
    print("Canonical Layer 0 \(edition.canonicalLayer0Version)")
    print("SHA-256 \(edition.canonicalLineSequenceSHA256)")
    print("")

    for unit in edition.orderedReadingUnits {
        print("=== \(unit.sequence): \(unit.id) | lines \(unit.canonicalAnchor.startLine)-\(unit.canonicalAnchor.endLine) ===")
        print(unit.canonicalText)
        print("")
    }
} catch {
    fputs("Stage 0 fixture failed to load: \(error)\n", stderr)
    exit(EXIT_FAILURE)
}
