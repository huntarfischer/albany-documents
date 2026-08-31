import Foundation
import Testing
@testable import JJWWReaderCore

@Suite("JJWW Stage 8B Canonical Ownership Spine")
struct Stage8BCanonicalOwnershipTests {
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

    @Test("The ownership spine is exactly 82 gapless canonical containers")
    func exactOwnershipGeometry() throws {
        let seal = try Stage8Layer1RebaseSeal.bundled()
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)

        #expect(ownership.canonicalLayer0Version == seal.targetLayer0.version)
        #expect(ownership.canonicalLineSequenceSHA256 == seal.targetLayer0.lineSequenceSHA256)
        #expect(ownership.containers.count == seal.expectedContainerCount)

        var nextLine = 1
        var ids = Set<String>()
        var blockIDs = Set<String>()

        for (index, container) in ownership.containers.enumerated() {
            #expect(container.id == String(format: "L1-CNT-%04d", index + 1))
            #expect(ids.insert(container.id).inserted)
            #expect(blockIDs.insert(container.layer0BlockID).inserted)
            #expect(container.canonicalAnchor.canonicalLayer0Version == "1.1")
            #expect(container.canonicalAnchor.startLine == nextLine)
            #expect(container.lines.first?.number == container.canonicalAnchor.startLine)
            #expect(container.lines.last?.number == container.canonicalAnchor.endLine)
            #expect(container.lines.map(\.number) == Array(container.canonicalAnchor.startLine...container.canonicalAnchor.endLine))
            nextLine = container.canonicalAnchor.endLine + 1
        }

        #expect(nextLine == 2070)
        #expect(ids.count == 82)
        #expect(blockIDs.count == 82)
    }

    @Test("Every canonical line 1 through 2069 has exactly one owner")
    func everyLineHasExactlyOneOwner() throws {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)

        for line in 1...2069 {
            let owners = ownership.containers.filter {
                $0.canonicalAnchor.contains(line: line)
            }
            #expect(owners.count == 1)
            #expect(ownership.container(containing: line)?.id == owners[0].id)
        }
    }

    @Test("Flattening the ownership spine reconstructs canonical v1.1 exactly")
    func exactCanonicalReconstruction() throws {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let directLines = try reconstructCanonicalLinesIndependently()

        #expect(ownership.lines.count == 2069)
        #expect(ownership.lines.map(\.number) == Array(1...2069))
        #expect(ownership.lines.map(\.text) == directLines)
        #expect(ownership.plainText() == directLines.joined(separator: "\n"))
    }

    @Test("The corrected June 18 passage belongs to L1-CNT-0019")
    func june18Ownership() throws {
        let ownership = try Stage8CanonicalOwnership.load(canonicalURL: canonicalURL)
        let owner = try #require(ownership.container(containing: 119))

        #expect(owner.id == "L1-CNT-0019")
        #expect(owner.layer0BlockID == "chunk-02-001")
        #expect(owner.canonicalAnchor == ReadingAnchor(
            canonicalLayer0Version: "1.1",
            startLine: 119,
            endLine: 127
        ))
        #expect(owner.lines.first?.text == "Monday June 18, 1827")
        #expect(owner.labelAsWritten == "Monday June 18, 1827")
    }

    @Test("Ownership is presentation-blind and contains no reader geometry")
    func ownershipHasNoPresentationGeometry() throws {
        let sourceURL = repositoryRoot.appendingPathComponent(
            "ios/JJWWReader/Sources/JJWWReaderCore/Stage8CanonicalOwnership.swift"
        )
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        #expect(!source.contains("SwiftUI"))
        #expect(!source.contains("CGFloat"))
        #expect(!source.contains("390"))
        #expect(!source.contains("844"))
        #expect(!source.contains("MaterialProfile"))
        #expect(!source.contains("TypographyProfile"))
        #expect(!source.contains("ReadingUnit"))
    }

    private func reconstructCanonicalLinesIndependently() throws -> [String] {
        let data = try Data(contentsOf: canonicalURL)
        let root = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let chunks = try #require(root["chunks"] as? [[String: Any]])
        var lines: [String] = []

        for chunk in chunks {
            let blocks = try #require(chunk["blocks"] as? [[String: Any]])
            for block in blocks {
                let type = try #require(block["type"] as? String)
                if type == "dated_entry" {
                    lines.append(try #require(block["date_text"] as? String))
                } else if type == "section" {
                    lines.append(try #require(block["heading"] as? String))
                }
                lines.append(contentsOf: try #require(block["lines"] as? [String]))
            }
        }

        return lines
    }
}
