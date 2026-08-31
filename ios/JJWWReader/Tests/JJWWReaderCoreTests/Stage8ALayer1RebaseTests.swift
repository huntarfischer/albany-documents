import CryptoKit
import Foundation
import Testing
@testable import JJWWReaderCore

@Suite("JJWW Stage 8A Layer 1 v1.1 Rebase")
struct Stage8ALayer1RebaseTests {
    private struct CanonicalBlock {
        let id: String
        let lines: [String]
    }

    private var repositoryRoot: URL {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let packageRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return packageRoot
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var canonicalURL: URL {
        repositoryRoot.appendingPathComponent(
            "jesse-james-and-the-widow-whipple-canonical-v1.1.json"
        )
    }

    private var structuralIndexURL: URL {
        repositoryRoot.appendingPathComponent("layer-1-structural-index(1).json")
    }

    private var sourceRegistryURL: URL {
        repositoryRoot.appendingPathComponent("layer-1-source-registry(1).json")
    }

    @Test("The v1.1 rebase seal preserves the sealed Layer 1 provenance")
    func rebaseSealProvenance() throws {
        let seal = try Stage8Layer1RebaseSeal.bundled()

        #expect(seal.formatVersion == "1.0-stage8-layer1-rebase")
        #expect(seal.sourceLayer0.version == "1.0")
        #expect(seal.sourceLayer0.lineCount == 2069)
        #expect(seal.sourceLayer0.lineSequenceSHA256 == "735edd6b4b60fdf1d019ac9baa0644ed21ce71bdf48018ef42634e38eef9fba7")
        #expect(seal.targetLayer0.version == "1.1")
        #expect(seal.targetLayer0.lineCount == 2069)
        #expect(seal.targetLayer0.lineSequenceSHA256 == "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e")
        #expect(seal.geometryUnchanged)
        #expect(seal.containerCorrections.count == 1)

        let correction = try #require(seal.containerCorrections.first)
        #expect(correction.containerID == "L1-CNT-0019")
        #expect(correction.lineStart == 119)
        #expect(correction.lineEnd == 127)
        #expect(correction.oldLabel == "Monday June 16, 1827")
        #expect(correction.newLabel == "Monday June 18, 1827")
        #expect(correction.oldTextSHA256 == "bce0874bce8cfea1c20a179b12d19f29f9e13747b0e56ea5293cc540e93a7b50")
        #expect(correction.newTextSHA256 == "08c39bd030c8d335caf372d86399a1a3bda4488ff1b98eec782e9075bdf0909f")
    }

    @Test("All 82 Layer 1 containers retain exact v1.1 canonical geometry")
    func containerGeometryIsUnchanged() throws {
        let seal = try Stage8Layer1RebaseSeal.bundled()
        let canonicalRoot = try loadJSONObject(canonicalURL)
        let structuralRoot = try loadJSONObject(structuralIndexURL)
        let blocks = try canonicalBlocks(in: canonicalRoot)
        let containers = try requireArray(structuralRoot["containers"])

        #expect(blocks.count == seal.expectedContainerCount)
        #expect(containers.count == seal.expectedContainerCount)

        var nextLine = 1
        for (index, pair) in zip(blocks, containers).enumerated() {
            let block = pair.0
            let container = try requireObject(pair.1)
            let start = try requireInt(container["line_start"])
            let end = try requireInt(container["line_end"])
            let count = try requireInt(container["line_count"])
            let blockID = try requireString(container["layer0_block_id"])
            let containerID = try requireString(container["container_id"])

            #expect(containerID == String(format: "L1-CNT-%04d", index + 1))
            #expect(blockID == block.id)
            #expect(start == nextLine)
            #expect(count == block.lines.count)
            #expect(end == start + count - 1)
            nextLine = end + 1
        }

        #expect(nextLine == 2070)
    }

    @Test("Only L1-CNT-0019 changes canonical text under v1.1")
    func exactlyOneContainerChanges() throws {
        let seal = try Stage8Layer1RebaseSeal.bundled()
        let correction = try #require(seal.containerCorrections.first)
        let canonicalRoot = try loadJSONObject(canonicalURL)
        let structuralRoot = try loadJSONObject(structuralIndexURL)
        let blocks = try canonicalBlocks(in: canonicalRoot)
        let containers = try requireArray(structuralRoot["containers"])

        let canonicalValidation = try requireObject(canonicalRoot["validation"])
        #expect(try requireString(canonicalValidation["line_sequence_sha256"]) == seal.targetLayer0.lineSequenceSHA256)
        #expect(try requireString(canonicalRoot["canonical_version"]) == seal.targetLayer0.version)

        let layer0Reference = try requireObject(structuralRoot["layer0_reference"])
        #expect(try requireString(layer0Reference["line_sequence_sha256"]) == seal.sourceLayer0.lineSequenceSHA256)

        var hashMismatches: [String] = []

        for (block, rawContainer) in zip(blocks, containers) {
            let container = try requireObject(rawContainer)
            let containerID = try requireString(container["container_id"])
            let storedHash = try requireString(container["text_sha256"])
            let canonicalHash = sha256(block.lines.joined(separator: "\n"))

            if storedHash != canonicalHash {
                hashMismatches.append(containerID)
            }

            if containerID == correction.containerID {
                let storedLabel = try requireString(container["label_as_written"])
                let canonicalLabel = try #require(block.lines.first)
                #expect(storedHash == correction.oldTextSHA256)
                #expect(canonicalHash == correction.newTextSHA256)
                #expect(storedLabel == correction.oldLabel)
                #expect(canonicalLabel == correction.newLabel)
            }
        }

        #expect(hashMismatches == [correction.containerID])

        let flattened = blocks.flatMap(\.lines)
        #expect(flattened.count == 2069)
        #expect(flattened[118] == "Monday June 18, 1827")
    }

    @Test("All 468 overlapping structural units remain in canonical bounds")
    func structuralUnitsRemainValid() throws {
        let seal = try Stage8Layer1RebaseSeal.bundled()
        let structuralRoot = try loadJSONObject(structuralIndexURL)
        let units = try requireArray(structuralRoot["units"])

        #expect(units.count == seal.expectedStructuralUnitCount)

        for rawUnit in units {
            let unit = try requireObject(rawUnit)
            let start = try requireInt(unit["line_start"])
            let end = try requireInt(unit["line_end"])
            #expect(start >= 1)
            #expect(end >= start)
            #expect(end <= seal.targetLayer0.lineCount)
        }
    }

    @Test("The full Layer 1 source registry survives the v1.1 coordinate rebase")
    func sourceRegistryRemainsValid() throws {
        let seal = try Stage8Layer1RebaseSeal.bundled()
        let sourceRoot = try loadJSONObject(sourceRegistryURL)

        var sourceIDs = Set<String>()
        var occurrenceIDs = Set<String>()
        var contextIDs = Set<String>()
        var checkedRanges = 0

        walkJSON(sourceRoot) { value in
            if let string = value as? String {
                if string.hasPrefix("L1-SRC-OCC-") {
                    occurrenceIDs.insert(string)
                } else if string.hasPrefix("L1-SRC-CTX-") {
                    contextIDs.insert(string)
                } else if string.hasPrefix("L1-SRC-") {
                    sourceIDs.insert(string)
                }
            }

            guard let object = value as? [String: Any],
                  let start = object["line_start"] as? Int,
                  let end = object["line_end"] as? Int else {
                return
            }

            checkedRanges += 1
            #expect(start >= 1)
            #expect(end >= start)
            #expect(end <= seal.targetLayer0.lineCount)
        }

        #expect(sourceIDs.count == seal.expectedSourceCount)
        #expect(occurrenceIDs.count == seal.expectedSourceOccurrenceCount)
        #expect(contextIDs.count == seal.expectedSourceContextCount)
        #expect(checkedRanges > 0)
    }

    private func loadJSONObject(_ url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        return try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
    }

    private func canonicalBlocks(in root: [String: Any]) throws -> [CanonicalBlock] {
        let chunks = try requireArray(root["chunks"])
        var result: [CanonicalBlock] = []

        for rawChunk in chunks {
            let chunk = try requireObject(rawChunk)
            for rawBlock in try requireArray(chunk["blocks"]) {
                let block = try requireObject(rawBlock)
                let id = try requireString(block["id"])
                let type = try requireString(block["type"])
                let body = try requireArray(block["lines"]).map { try requireString($0) }
                let lines: [String]

                switch type {
                case "dated_entry":
                    lines = [try requireString(block["date_text"])] + body
                case "section":
                    lines = [try requireString(block["heading"])] + body
                default:
                    lines = body
                }

                result.append(CanonicalBlock(id: id, lines: lines))
            }
        }

        return result
    }

    private func requireObject(_ value: Any?) throws -> [String: Any] {
        try #require(value as? [String: Any])
    }

    private func requireArray(_ value: Any?) throws -> [Any] {
        try #require(value as? [Any])
    }

    private func requireString(_ value: Any?) throws -> String {
        try #require(value as? String)
    }

    private func requireInt(_ value: Any?) throws -> Int {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        Issue.record("Expected integer JSON value")
        return 0
    }

    private func sha256(_ string: String) -> String {
        SHA256.hash(data: Data(string.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func walkJSON(_ value: Any, visit: (Any) -> Void) {
        visit(value)
        if let object = value as? [String: Any] {
            for child in object.values {
                walkJSON(child, visit: visit)
            }
        } else if let array = value as? [Any] {
            for child in array {
                walkJSON(child, visit: visit)
            }
        }
    }
}
