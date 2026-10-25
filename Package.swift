// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "hanyeong-auto",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "HanyeongAuto", targets: ["HanyeongAuto"]),
    ],
    targets: [
        .target(name: "HanyeongCore"),
        .executableTarget(
            name: "HanyeongAuto",
            dependencies: ["HanyeongCore"],
            linkerSettings: [.linkedFramework("InputMethodKit"), .linkedFramework("Carbon")]
        ),
        .testTarget(name: "HanyeongCoreTests", dependencies: ["HanyeongCore"]),
    ]
)
