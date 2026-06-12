// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SofiaCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SofiaCore", targets: ["SofiaCore"]),
        .executable(name: "SofiaCoreSmokeTest", targets: ["SofiaCoreSmokeTest"]),
    ],
    targets: [
        .target(
            name: "SofiaCore",
            path: "Sources/SofiaCore"
        ),
        .executableTarget(
            name: "SofiaCoreSmokeTest",
            dependencies: ["SofiaCore"],
            path: "Sources/SofiaCoreSmokeTest"
        ),
        .testTarget(
            name: "SofiaCoreTests",
            dependencies: ["SofiaCore"],
            path: "Tests/SofiaCoreTests"
        ),
    ]
)