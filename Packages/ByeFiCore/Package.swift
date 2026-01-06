// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ByeFiCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ByeFiCore", targets: ["ByeFiCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/Defaults", from: "9.0.6"),
    ],
    targets: [
        .target(
            name: "ByeFiCore",
            dependencies: [
                .product(name: "Defaults", package: "Defaults"),
            ],
            path: "Sources/ByeFiCore",
            linkerSettings: [
                .linkedFramework("CoreWLAN"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "ByeFiCoreTests",
            dependencies: ["ByeFiCore"],
            path: "Tests/ByeFiCoreTests"
        ),
    ]
)
