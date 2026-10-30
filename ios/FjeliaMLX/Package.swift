// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FjeliaMLX",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "FjeliaMLX", targets: ["FjeliaMLX"])],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", exact: "2.31.3"),
    ],
    targets: [
        .target(
            name: "FjeliaMLX",
            dependencies: [
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "FjeliaMLXTests", dependencies: ["FjeliaMLX"]),
    ]
)
