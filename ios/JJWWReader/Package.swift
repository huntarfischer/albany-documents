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
        .library(name: "JJWWMaterialLab", targets: ["JJWWMaterialLab"]),
        .executable(name: "jjww-stage0-print", targets: ["JJWWStage0Print"]),
        .executable(name: "jjww-material-specimens", targets: ["JJWWMaterialSpecimens"]),
        .executable(name: "jjww-material-lab-snapshot", targets: ["JJWWMaterialLabSnapshot"]),
        .executable(name: "jjww-typography-specimens", targets: ["JJWWTypographySpecimens"]),
        .executable(name: "jjww-scroll-reader-snapshot", targets: ["JJWWScrollReaderSnapshot"]),
        .executable(name: "jjww-pagination-snapshot", targets: ["JJWWPaginationSnapshot"])
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
            name: "JJWWMaterialLab",
            dependencies: ["JJWWMaterials", "JJWWTypography"]
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
            name: "JJWWMaterialLabTests",
            dependencies: ["JJWWMaterials", "JJWWMaterialLab", "JJWWTypography"]
        )
    ]
)
