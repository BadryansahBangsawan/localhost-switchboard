// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalhostSwitchboard",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "LocalhostSwitchboard", targets: ["LocalhostSwitchboard"])
    ],
    targets: [
        .executableTarget(name: "LocalhostSwitchboard", path: "Sources")
    ]
)
