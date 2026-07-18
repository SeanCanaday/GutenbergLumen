// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GutenbergLumenKit",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "GutenbergLumenKit", targets: ["GutenbergLumenKit"]),
    ],
    targets: [
        .target(name: "GutenbergLumenKit"),
        .testTarget(name: "GutenbergLumenKitTests", dependencies: ["GutenbergLumenKit"]),
    ]
)
