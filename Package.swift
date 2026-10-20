// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Showtime",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "ShowtimeCore"),
        .executableTarget(name: "Showtime", dependencies: ["ShowtimeCore"]),
        .testTarget(name: "ShowtimeCoreTests", dependencies: ["ShowtimeCore"]),
    ],
    swiftLanguageModes: [.v5]
)
