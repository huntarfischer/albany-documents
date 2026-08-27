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
        .executable(name: "jjww-stage0-print", targets: ["JJWWStage0Print"]),
        .executable(name: "jjww-material-specimens", targets: ["JJWWMaterialSpecimens"])
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
        .executableTarget(
            name: "JJWWStage0Print",
            dependencies: ["JJWWReaderCore"]
        ),
        .executableTarget(
            name: "JJWWMaterialSpecimens",
            dependencies: ["JJWWMaterials"]
        ),
        .testTarget(
            name: "JJWWReaderCoreTests",
            dependencies: ["JJWWReaderCore"]
        ),
        .testTarget(
            name: "JJWWMaterialsTests",
            dependencies: ["JJWWMaterials"]
        )
    ]
)
