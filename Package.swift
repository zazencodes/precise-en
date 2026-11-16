// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "PreciseEN",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "PreciseKit", targets: ["PreciseKit"]),
        .library(name: "PreciseUI", targets: ["PreciseUI"]),
        .executable(name: "precise-en", targets: ["PreciseCLI"]),
    ],
    targets: [
        .target(name: "PreciseKit"),
        .target(name: "PreciseUI", dependencies: ["PreciseKit"]),
        .executableTarget(name: "PreciseCLI", dependencies: ["PreciseKit"]),
        .testTarget(name: "PreciseKitTests", dependencies: ["PreciseKit"]),
        .testTarget(name: "PreciseUITests", dependencies: ["PreciseUI"]),
        .testTarget(name: "PreciseCLITests", dependencies: ["PreciseCLI"]),
    ]
)
