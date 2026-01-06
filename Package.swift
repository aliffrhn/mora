// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mora",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Mora",
            targets: ["Mora"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.1.0"),
        .package(url: "https://github.com/pointfreeco/combine-schedulers.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Mora",
            dependencies: [
                "HotKey",
                .product(name: "CombineSchedulers", package: "combine-schedulers")
            ],
            path: "Mora",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MoraTests",
            dependencies: ["Mora"],
            path: "Tests/MoraTests"
        )
    ]
)
