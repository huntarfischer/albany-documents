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
/// anywhere inside it appears in the developer gallery automatically. The manifest
/// adds the scholarly/editorial metadata needed to place an image into the authored flow.
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
        let listedByRelativePath: [String: URL]
        let listedByName: [String: URL]

        if let galleryURL {
            listedByRelativePath = Dictionary(
                uniqueKeysWithValues: listedFiles.map {
                    (relativeGalleryPath(for: $0, relativeTo: galleryURL), $0)
                }
            )
        } else {
            listedByRelativePath = [:]
        }

        listedByName = listedFiles.reduce(into: [:]) { result, url in
            if result[url.lastPathComponent] == nil {
                result[url.lastPathComponent] = url
            }
        }

        var resolved = manifest.assets.map { descriptor in
            ResolvedEditorialAsset(
                descriptor: descriptor,
                resourceURL: listedByRelativePath[descriptor.filename] ?? listedByName[descriptor.filename],
                discoveredAutomatically: false
            )
        }

        let manifestFilenames = Set(manifest.assets.map(\.filename))
        for url in listedFiles {
            let relativePath = galleryURL.map {
                relativeGalleryPath(for: url, relativeTo: $0)
            } ?? url.lastPathComponent

            guard !manifestFilenames.contains(relativePath),
                  !manifestFilenames.contains(url.lastPathComponent) else {
                continue
            }

            let descriptor = EditorialAssetDescriptor(
                id: "unfiled.\(slug(relativePath))",
                filename: relativePath,
                role: .researchImage,
                title: humanizedFilename(url.deletingPathExtension().lastPathComponent),
                altText: "",
                insertionStyle: .inline,
                placement: nil,
                notes: "Auto-discovered research image. Add this Gallery-relative filename to editorial-gallery-manifest-v0.1.json to caption or place it."
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

    static func discoverImageFiles(at directoryURL: URL?) -> [URL] {
        guard let directoryURL,
              let enumerator = FileManager.default.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
              ) else {
            return []
        }

        let extensions = Set(["png", "jpg", "jpeg", "heic", "tif", "tiff"])
        var urls: [URL] = []

        for case let url as URL in enumerator {
            guard extensions.contains(url.pathExtension.lowercased()),
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
                continue
            }
            urls.append(url)
        }

        return urls.sorted { $0.path < $1.path }
    }

    private static func relativeGalleryPath(for url: URL, relativeTo directoryURL: URL) -> String {
        let rootPath = directoryURL.standardizedFileURL.path
        let filePath = url.standardizedFileURL.path
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"

        guard filePath.hasPrefix(prefix) else {
            return url.lastPathComponent
        }
        return String(filePath.dropFirst(prefix.count))
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
