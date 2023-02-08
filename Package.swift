// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SwiftFileSystemEvents",
    products: [.library(name: "SwiftFileSystemEvents", targets: ["SwiftFileSystemEvents"])],
    targets: [
        .target(name: "SwiftFileSystemEvents"),
        .testTarget(name: "SwiftFileSystemEventsTests", dependencies: ["SwiftFileSystemEvents"])
    ]
)
