// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SimpleSwiftUIApp",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "SimpleSwiftUIApp", targets: ["SimpleSwiftUIApp"])
    ],
    targets: [
        .executableTarget(
            name: "SimpleSwiftUIApp",
            path: "Sources",
        )
    ]
)
