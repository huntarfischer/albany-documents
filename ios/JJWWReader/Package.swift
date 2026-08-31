// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "JJWWReader",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "JJWWReaderCore", targets: ["JJWWReaderCore"]),
        .library(name: "JJWWMaterials", targets: ["JJWWMaterials"]),
        .library(name: "JJWWTypography", targets: ["JJWWTypography"]),
        .library(name: "JJWWScrollReader", targets: ["JJWWScrollReader"]),
        .library(name: "JJWWPagination", targets: ["JJWWPagination"]),
        .library(name: "JJWWPagesReader", targets: ["JJWWPagesReader"]),
        .library(name: "JJWWBookShell", targets: ["JJWWBookShell"]),
        .library(name: "JJWWMaterialLab", targets: ["JJWWMaterialLab"]),
        .executable(name: "jjww-stage0-print", targets: ["JJWWStage0Print"]),
        .executable(name: "jjww-material-specimens", targets: ["JJWWMaterialSpecimens"]),
        .executable(name: "jjww-material-lab-snapshot", targets: ["JJWWMaterialLabSnapshot"]),
        .executable(name: "jjww-typography-specimens", targets: ["JJWWTypographySpecimens"]),
        .executable(name: "jjww-scroll-reader-snapshot", targets: ["JJWWScrollReaderSnapshot"]),
        .executable(name: "jjww-pagination-snapshot", targets: ["JJWWPaginationSnapshot"]),
        .executable(name: "jjww-pages-reader-snapshot", targets: ["JJWWPagesReaderSnapshot"]),
        .executable(name: "jjww-stage7-binding-snapshot", targets: ["JJWWBookShellSnapshot"]),
        .executable(name: "jjww-stage7-5-snapshot", targets: ["JJWWStage75Snapshot"])
    ],
    targets: [
        .target(
            name: "JJWWReaderCore",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "JJWWMaterials",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "JJWWTypography",
            dependencies: ["JJWWReaderCore", "JJWWMaterials"]
        ),
        .target(
            name: "JJWWScrollReader",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWTypography"]
        ),
        .target(
            name: "JJWWPagination",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWTypography", "JJWWScrollReader"]
        ),
        .target(
            name: "JJWWPagesReader",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWTypography", "JJWWScrollReader", "JJWWPagination"]
        ),
        .target(
            name: "JJWWBookShell",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWTypography", "JJWWScrollReader", "JJWWPagination", "JJWWPagesReader"],
            resources: [
                .process("Resources/editorial-gallery-manifest-v0.1.json"),
                .copy("Resources/Gallery")
            ]
        ),
        .target(
            name: "JJWWMaterialLab",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWTypography", "JJWWScrollReader", "JJWWPagination", "JJWWBookShell"]
        ),
        .executableTarget(
            name: "JJWWStage0Print",
            dependencies: ["JJWWReaderCore"]
        ),
        .executableTarget(
            name: "JJWWMaterialSpecimens",
            dependencies: ["JJWWMaterials"]
        ),
        .executableTarget(
            name: "JJWWMaterialLabSnapshot",
            dependencies: ["JJWWMaterials", "JJWWMaterialLab", "JJWWTypography"]
        ),
        .executableTarget(
            name: "JJWWTypographySpecimens",
            dependencies: ["JJWWMaterials", "JJWWTypography"]
        ),
        .executableTarget(
            name: "JJWWScrollReaderSnapshot",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWTypography", "JJWWScrollReader"]
        ),
        .executableTarget(
            name: "JJWWPaginationSnapshot",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWTypography", "JJWWScrollReader", "JJWWPagination"]
        ),
        .executableTarget(
            name: "JJWWPagesReaderSnapshot",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWScrollReader", "JJWWPagination", "JJWWPagesReader"]
        ),
        .executableTarget(
            name: "JJWWBookShellSnapshot",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWScrollReader", "JJWWPagination", "JJWWPagesReader", "JJWWBookShell"]
        ),
        .executableTarget(
            name: "JJWWStage75Snapshot",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWScrollReader", "JJWWPagination", "JJWWPagesReader", "JJWWBookShell"]
        ),
        .testTarget(
            name: "JJWWReaderCoreTests",
            dependencies: ["JJWWReaderCore"]
        ),
        .testTarget(
            name: "JJWWMaterialsTests",
            dependencies: ["JJWWMaterials"]
        ),
        .testTarget(
            name: "JJWWTypographyTests",
            dependencies: ["JJWWTypography"]
        ),
        .testTarget(
            name: "JJWWScrollReaderTests",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWTypography", "JJWWScrollReader"]
        ),
        .testTarget(
            name: "JJWWPaginationTests",
            dependencies: ["JJWWReaderCore", "JJWWTypography", "JJWWScrollReader", "JJWWPagination"]
        ),
        .testTarget(
            name: "JJWWPagesReaderTests",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWScrollReader", "JJWWPagination", "JJWWPagesReader"]
        ),
        .testTarget(
            name: "JJWWBookShellTests",
            dependencies: ["JJWWReaderCore", "JJWWMaterials", "JJWWScrollReader", "JJWWPagination", "JJWWPagesReader", "JJWWBookShell"]
        ),
        .testTarget(
            name: "JJWWMaterialLabTests",
            dependencies: ["JJWWMaterials", "JJWWMaterialLab", "JJWWTypography"]
        )
    ]
)
