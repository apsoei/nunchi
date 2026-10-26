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
            // IMKInputController 는 동시성 표시가 없는 Objective-C 클래스라 Swift 5 모드로 둔다.
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [.linkedFramework("InputMethodKit"), .linkedFramework("Carbon")]
        ),
        .testTarget(name: "HanyeongCoreTests", dependencies: ["HanyeongCore"]),
    ]
)
