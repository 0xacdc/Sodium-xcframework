// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Clibsodium",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v11)
    ],
    products: [
        .library(name: "Clibsodium", targets: ["Clibsodium"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(name: "Clibsodium", path: "Clibsodium.xcframework")
    ]
)
