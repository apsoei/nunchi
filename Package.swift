// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "nunchi",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Nunchi", targets: ["Nunchi"]),
    ],
    targets: [
        .target(name: "NunchiCore"),
        .executableTarget(
            name: "Nunchi",
            dependencies: ["NunchiCore"],
            // IMKInputController 는 동시성 표시가 없는 Objective-C 클래스라 Swift 5 모드로 둔다.
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [.linkedFramework("InputMethodKit"), .linkedFramework("Carbon")]
        ),
        .testTarget(name: "NunchiCoreTests", dependencies: ["NunchiCore"]),
    ]
)
