// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ByeFiCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ByeFiCore", targets: ["ByeFiCore"]),
    ],
    targets: [
        .target(
            name: "ByeFiCore",
            path: "Sources/ByeFiCore"
        ),
    ]
)
