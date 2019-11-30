// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "fluent",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "Fluent", targets: ["Fluent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/skelpo/fluent-kit.git", from: "1.0.0-beta.2.4"),
        .package(url: "https://github.com/skelpo/async-kit.git", from: "1.0.0-beta.1.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta"),
    ],
    targets: [
        .target(name: "Fluent", dependencies: ["FluentKit", "Vapor"]),
        .testTarget(name: "FluentTests", dependencies: ["Fluent"]),
    ]
)
