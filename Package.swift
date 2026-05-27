// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PayloadSender",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PayloadSender", targets: ["PS5PayloadSenderApp"]),
        .library(name: "PS5PayloadKit", targets: ["PS5PayloadKit"])
    ],
    targets: [
        .target(
            name: "PS5PayloadKit"
        ),
        .executableTarget(
            name: "PS5PayloadSenderApp",
            dependencies: ["PS5PayloadKit"]
        ),
        .testTarget(
            name: "PS5PayloadKitTests",
            dependencies: ["PS5PayloadKit"]
        )
    ]
)
