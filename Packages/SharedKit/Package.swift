// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SharedKit",
            targets: ["SharedKit"]
        )
    ],
    targets: [
        .target(
            name: "SharedKit"
        ),
        .testTarget(
            name: "SharedKitTests",
            dependencies: ["SharedKit"]
        )
    ]
)
