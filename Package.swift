// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EventTicketingSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "EventTicketingSDK",
            targets: ["EventTicketingSDK"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "EventTicketingSDK",
            dependencies: []),
        .testTarget(
            name: "EventTicketingSDKTests",
            dependencies: ["EventTicketingSDK"])
    ]
)