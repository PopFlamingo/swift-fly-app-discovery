// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftFlyAppDiscovery",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FlyAppDiscovery",
            targets: ["FlyAppDiscovery"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-service-discovery.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-distributed-actors.git", revision: "1.0.0-beta.1.1"),
        .package(url: "https://github.com/PopFlamingo/NioDNS.git", branch: "txt-rawvalues")

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FlyAppDiscovery",
            dependencies: [
                .product(name: "ServiceDiscovery", package: "swift-service-discovery"),
                .product(name: "DistributedActors", package: "swift-distributed-actors"),
                .product(name: "DNSClient", package: "NioDNS")
            ]
        ),
        .testTarget(
            name: "SwiftFlyAppDiscoveryTests",
            dependencies: ["FlyAppDiscovery"]),
    ]
)
