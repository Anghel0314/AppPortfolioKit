// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppPortfolioKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AppPortfolioKit",
            targets: ["AppPortfolioKit"]
        )
    ],
    targets: [
        .target(name: "AppPortfolioKit"),
        .testTarget(
            name: "AppPortfolioKitTests",
            dependencies: ["AppPortfolioKit"]
        )
    ]
)
