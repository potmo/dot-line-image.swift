// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DotterPack",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "DotterPack",
            targets: ["DotterPack"]),
    ],
    dependencies: [
        .package(url: "https://github.com/heckj/CameraControlARView", exact: Version(0, 5, 0))
    ],
    targets: [
        .executableTarget(
            name: "DotterPack",
            dependencies: [
                .product(name: "CameraControlARView", package: "CameraControlARView")
            ],
            resources: [
                .process("Resources"),
            ]),
    ]
)
