// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MultiCopy",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "MultiCopy",
            targets: ["MultiCopy"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MultiCopy",
            path: "Sources"
        )
    ]
)