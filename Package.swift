// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "thesis-server",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "App", targets: ["App"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
