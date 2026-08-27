import Foundation

public enum EditorialAssetRole: String, Codable, CaseIterable, Sendable {
    case cover
    case delayedTitlePlate
    case publisherMark
    case researchImage
    case illustration
    case map
    case facsimile
}

public enum EditorialInsertionStyle: String, Codable, CaseIterable, Sendable {
    case cover
    case fullPagePlate
    case inline
    case captioned
    case fullBleed
}

public enum EditorialPlacementEdge: String, Codable, CaseIterable, Sendable {
    case before
    case after
}

public struct EditorialAssetPlacement: Codable, Equatable, Sendable {
    public let canonicalLine: Int
    public let edge: EditorialPlacementEdge

    public init(canonicalLine: Int, edge: EditorialPlacementEdge) {
        self.canonicalLine = canonicalLine
        self.edge = edge
    }
}

public struct EditorialAssetDescriptor: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let filename: String
    public let role: EditorialAssetRole
    public let title: String
    public let caption: String?
    public let credit: String?
    public let altText: String
    public let insertionStyle: EditorialInsertionStyle
    public let placement: EditorialAssetPlacement?
    public let notes: String?

    public init(
        id: String,
        filename: String,
        role: EditorialAssetRole,
        title: String,
        caption: String? = nil,
        credit: String? = nil,
        altText: String = "",
        insertionStyle: EditorialInsertionStyle = .inline,
        placement: EditorialAssetPlacement? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.filename = filename
        self.role = role
        self.title = title
        self.caption = caption
        self.credit = credit
        self.altText = altText
        self.insertionStyle = insertionStyle
        self.placement = placement
        self.notes = notes
    }
}

public struct EditorialGalleryManifest: Codable, Equatable, Sendable {
    public let version: String
    public let assets: [EditorialAssetDescriptor]

    public init(version: String, assets: [EditorialAssetDescriptor]) {
        self.version = version
        self.assets = assets
    }
}

public struct ResolvedEditorialAsset: Equatable, Identifiable, Sendable {
    public let descriptor: EditorialAssetDescriptor
    public let resourceURL: URL?
    public let discoveredAutomatically: Bool

    public init(
        descriptor: EditorialAssetDescriptor,
        resourceURL: URL?,
        discoveredAutomatically: Bool = false
    ) {
        self.descriptor = descriptor
        self.resourceURL = resourceURL
        self.discoveredAutomatically = discoveredAutomatically
    }

    public var id: String { descriptor.id }
    public var isAvailable: Bool { resourceURL != nil }
    public var isPlaced: Bool { descriptor.placement != nil }
}

public enum EditorialGalleryError: Error, Equatable {
    case manifestMissing
    case invalidManifest
}

/// Stage 7 image library.
///
/// The Gallery directory is intentionally forgiving: any supported image dropped
/// into it appears in the developer gallery automatically. The manifest adds the
/// scholarly/editorial metadata needed to place an image into the authored flow.
public struct EditorialGalleryStore: Sendable {
    public static let expectedManifestVersion = "0.1"

    public let manifestVersion: String
    public let assets: [ResolvedEditorialAsset]

    public init(manifestVersion: String, assets: [ResolvedEditorialAsset]) {
        self.manifestVersion = manifestVersion
        self.assets = assets
    }

    public static func bundled() throws -> EditorialGalleryStore {
        guard let manifestURL = Bundle.module.url(
            forResource: "editorial-gallery-manifest-v0.1",
            withExtension: "json"
        ) else {
            throw EditorialGalleryError.manifestMissing
        }

        guard let manifest = try? JSONDecoder().decode(
            EditorialGalleryManifest.self,
            from: Data(contentsOf: manifestURL)
        ), manifest.version == expectedManifestVersion else {
            throw EditorialGalleryError.invalidManifest
        }

        let galleryURL = Bundle.module.resourceURL?.appendingPathComponent("Gallery", isDirectory: true)
        let listedFiles = discoverImageFiles(at: galleryURL)
        let listedByName = Dictionary(uniqueKeysWithValues: listedFiles.map { ($0.lastPathComponent, $0) })

        var resolved = manifest.assets.map { descriptor in
            ResolvedEditorialAsset(
                descriptor: descriptor,
                resourceURL: listedByName[descriptor.filename],
                discoveredAutomatically: false
            )
        }

        let manifestFilenames = Set(manifest.assets.map(\.filename))
        for url in listedFiles where !manifestFilenames.contains(url.lastPathComponent) {
            let descriptor = EditorialAssetDescriptor(
                id: "unfiled.\(slug(url.deletingPathExtension().lastPathComponent))",
                filename: url.lastPathComponent,
                role: .researchImage,
                title: humanizedFilename(url.deletingPathExtension().lastPathComponent),
                altText: "",
                insertionStyle: .inline,
                placement: nil,
                notes: "Auto-discovered. Add this filename to editorial-gallery-manifest-v0.1.json to caption or place it."
            )
            resolved.append(
                ResolvedEditorialAsset(
                    descriptor: descriptor,
                    resourceURL: url,
                    discoveredAutomatically: true
                )
            )
        }

        return EditorialGalleryStore(
            manifestVersion: manifest.version,
            assets: resolved.sorted { lhs, rhs in
                let lhsOrder = roleOrder(lhs.descriptor.role)
                let rhsOrder = roleOrder(rhs.descriptor.role)
                if lhsOrder == rhsOrder { return lhs.descriptor.title < rhs.descriptor.title }
                return lhsOrder < rhsOrder
            }
        )
    }

    public func asset(id: String) -> ResolvedEditorialAsset? {
        assets.first { $0.id == id }
    }

    public func firstAsset(role: EditorialAssetRole) -> ResolvedEditorialAsset? {
        assets.first { $0.descriptor.role == role }
    }

    public func assets(
        atCanonicalLine line: Int,
        edge: EditorialPlacementEdge
    ) -> [ResolvedEditorialAsset] {
        assets.filter {
            $0.descriptor.placement?.canonicalLine == line &&
            $0.descriptor.placement?.edge == edge
        }
    }

    public var unplacedAssets: [ResolvedEditorialAsset] {
        assets.filter { !$0.isPlaced }
    }

    public var missingManifestAssets: [ResolvedEditorialAsset] {
        assets.filter { !$0.isAvailable && !$0.discoveredAutomatically }
    }

    private static func discoverImageFiles(at directoryURL: URL?) -> [URL] {
        guard let directoryURL,
              let urls = try? FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        let extensions = Set(["png", "jpg", "jpeg", "heic", "tif", "tiff"])
        return urls.filter { extensions.contains($0.pathExtension.lowercased()) }
    }

    private static func slug(_ string: String) -> String {
        let pieces = string.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        let value = pieces.filter { !$0.isEmpty }.joined(separator: "-")
        return value.isEmpty ? "image" : value
    }

    private static func humanizedFilename(_ string: String) -> String {
        let pieces = string.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return pieces.filter { !$0.isEmpty }.joined(separator: " ")
    }

    private static func roleOrder(_ role: EditorialAssetRole) -> Int {
        switch role {
        case .cover: return 0
        case .publisherMark: return 1
        case .delayedTitlePlate: return 2
        case .map: return 3
        case .illustration: return 4
        case .facsimile: return 5
        case .researchImage: return 6
        }
    }
}
