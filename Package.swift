// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PointClickSdk",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PointClickSdk",
            targets: ["PointClickSdk"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "PointClickSdk",
            path: "PointClickSdk.xcframework"
        )
    ]
)
