// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SwiftFileSystemEvents",
    platforms: [.macOS(.v10_13)],
    products: [.library(name: "SwiftFileSystemEvents", targets: ["SwiftFileSystemEvents"])],
    targets: [
        .target(name: "SwiftFileSystemEvents"),
        .testTarget(name: "SwiftFileSystemEventsTests", dependencies: ["SwiftFileSystemEvents"])
    ]
)
