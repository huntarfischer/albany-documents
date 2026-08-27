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
        .library(name: "JJWWMaterialLab", targets: ["JJWWMaterialLab"]),
        .executable(name: "jjww-stage0-print", targets: ["JJWWStage0Print"]),
        .executable(name: "jjww-material-specimens", targets: ["JJWWMaterialSpecimens"]),
        .executable(name: "jjww-material-lab-snapshot", targets: ["JJWWMaterialLabSnapshot"])
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
            name: "JJWWMaterialLab",
            dependencies: ["JJWWMaterials"]
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
            dependencies: ["JJWWMaterials", "JJWWMaterialLab"]
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
            name: "JJWWMaterialLabTests",
            dependencies: ["JJWWMaterials", "JJWWMaterialLab"]
        )
    ]
)
