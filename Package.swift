// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacPreviewUtils",
    platforms: [.macOS(.v11)],
    products: [
        .library(
            name: "MacPreviewUtils",
            targets: ["MacPreviewUtils", "MacPreviewUtilsObjC"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MacPreviewUtils",
            dependencies: []),
        .target(
            name: "MacPreviewUtilsObjC",
            dependencies: [
                .target(name: "MacPreviewUtils")
            ]),
    ]
)
