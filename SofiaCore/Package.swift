// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SofiaCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SofiaCore",
            targets: ["SofiaCore"]
        ),
    ],
    targets: [
        .target(
            name: "SofiaCore",
            path: "Sources/SofiaCore"
        ),
    ]
)
