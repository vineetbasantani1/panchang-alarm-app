// swift-tools-version: 5.9
import PackageDescription
 
// This package holds the VERIFIED, TESTABLE core logic only: the tithi
// astronomy calculations and data models. It is a plain Swift library —
// no SwiftUI, no AlarmKit, no app-specific machinery — so it builds and
// tests cleanly with a standard `swift build` / `swift test`, with no
// ambiguity about Xcode project format.
//
// The actual iOS app (SwiftUI views + AlarmKit) lives in /AppSources and
// is NOT part of this package. See README.md for why, and for the exact
// steps to assemble them into a real Xcode App project.
 
let package = Package(
    name: "PanchangAlarmCore",
    platforms: [
        .iOS(.v17), .macOS(.v13)
    ],
    products: [
        .library(
            name: "PanchangAlarmCore",
            targets: ["PanchangAlarmCore"]
        )
    ],
    targets: [
        .target(
            name: "PanchangAlarmCore",
            path: "Sources/PanchangAlarmCore"
        ),
        .testTarget(
            name: "PanchangAlarmCoreTests",
            dependencies: ["PanchangAlarmCore"],
            path: "Tests/PanchangAlarmCoreTests"
        )
    ]
)
 



