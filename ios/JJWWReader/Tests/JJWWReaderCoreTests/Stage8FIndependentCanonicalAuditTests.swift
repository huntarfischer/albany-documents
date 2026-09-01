import CryptoKit
import Foundation
import Testing
@testable import JJWWReaderCore

@Suite("JJWW Stage 8F Independent Canonical Reconstruction")
struct Stage8FIndependentCanonicalAuditTests {
    private struct RawCanonicalBlock: Equatable {
        let id: String
        let lines: [String]
    }

    private let expectedCanonicalVersion = "1.1"
    private let expectedCanonicalSHA256 = "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e"

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

    @Test("Raw canonical v1.1 independently reconstructs 82 blocks and 2,069 ordered lines")
    func rawCanonicalShape() throws {
        let raw = try loadRawCanonical()
        let flattened = raw.blocks.flatMap(\.lines)

        #expect(raw.version == expectedCanonicalVersion)
        #expect(raw.sealedSHA256 == expectedCanonicalSHA256)
        #expect(raw.blocks.count == 82)
        #expect(flattened.count == 2069)
        #expect(flattened.first == "[ Image: LOGO BLACK.png ]")
        #expect(flattened[118] == "Monday June 18, 1827")
        #expect(flattened.last != nil)
    }

    @Test("Production Edition independently contains exactly 75 units, 82 blocks, and 2,069 unique numbered lines")
    func productionEditionShape() throws {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let units = edition.orderedReadingUnits
        let blocks = units.flatMap(\.blocks)
        let lines = blocks.flatMap(\.lines)

        #expect(units.count == 75)
        #expect(blocks.count == 82)
        #expect(lines.count == 2069)
        #expect(lines.map(\.number) == Array(1...2069))
        #expect(Set(lines.map(\.number)).count == 2069)
        #expect(Set(blocks.map(\.id)).count == 82)
    }

    @Test("Production Edition strings equal independently reconstructed raw canonical strings line for line")
    func exactLineForLineEquality() throws {
        let raw = try loadRawCanonical()
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let productionLines = edition.orderedReadingUnits
            .flatMap(\.blocks)
            .flatMap(\.lines)

        let rawLines = raw.blocks.flatMap(\.lines)
        #expect(productionLines.count == rawLines.count)

        for index in rawLines.indices {
            #expect(productionLines[index].number == index + 1)
            #expect(productionLines[index].text == rawLines[index])
        }
    }

    @Test("Production block boundaries equal independently reconstructed raw canonical block boundaries")
    func exactBlockBoundaryEquality() throws {
        let raw = try loadRawCanonical()
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let productionBlocks = edition.orderedReadingUnits.flatMap(\.blocks)

        #expect(productionBlocks.count == raw.blocks.count)

        var nextLine = 1
        for index in raw.blocks.indices {
            let rawBlock = raw.blocks[index]
            let productionBlock = productionBlocks[index]
            let expectedStart = nextLine
            let expectedEnd = expectedStart + rawBlock.lines.count - 1

            #expect(productionBlock.canonicalAnchor.startLine == expectedStart)
            #expect(productionBlock.canonicalAnchor.endLine == expectedEnd)
            #expect(productionBlock.lines.map(\.text) == rawBlock.lines)
            nextLine = expectedEnd + 1
        }

        #expect(nextLine == 2070)
    }

    @Test("Production Edition recomputes to the sealed canonical v1.1 SHA-256")
    func productionSHAIsCanonical() throws {
        let raw = try loadRawCanonical()
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let productionText = edition.orderedReadingUnits
            .flatMap(\.blocks)
            .flatMap(\.lines)
            .map(\.text)
            .joined(separator: "\n")
        let rawText = raw.blocks.flatMap(\.lines).joined(separator: "\n")

        #expect(productionText == rawText)
        #expect(sha256(productionText) == expectedCanonicalSHA256)
        #expect(edition.canonicalLineSequenceSHA256 == expectedCanonicalSHA256)
        #expect(raw.sealedSHA256 == expectedCanonicalSHA256)
    }

    @Test("8F audit reaches canonical truth without using ownership or Edition-map loaders on the raw side")
    func auditBoundaryIsIndependent() throws {
        let testSource = try String(contentsOf: URL(fileURLWithPath: #filePath), encoding: .utf8)
        let ownershipLoaderSymbol = "Stage8Canonical" + "Ownership.load"
        let editionMapLoaderSymbol = "Stage8Edition" + "Map.load"

        #expect(testSource.contains("JSONSerialization.jsonObject"))
        #expect(!testSource.contains(ownershipLoaderSymbol))
        #expect(!testSource.contains(editionMapLoaderSymbol))
    }

    private func loadRawCanonical() throws -> (
        version: String,
        sealedSHA256: String,
        blocks: [RawCanonicalBlock]
    ) {
        let data = try Data(contentsOf: canonicalURL)
        let root = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let version = try requireString(root["canonical_version"])
        let validation = try requireObject(root["validation"])
        let sealedSHA256 = try requireString(validation["line_sequence_sha256"])
        let chunks = try requireArray(root["chunks"])
        var blocks: [RawCanonicalBlock] = []

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

                blocks.append(RawCanonicalBlock(id: id, lines: lines))
            }
        }

        return (version, sealedSHA256, blocks)
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

    private func sha256(_ string: String) -> String {
        SHA256.hash(data: Data(string.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
