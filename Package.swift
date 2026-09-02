// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PanchangAlarm",
    platforms: [
        .iOS("26.0")
    ],
    products: [
        .iOSApplication(
            name: "PanchangAlarm",
            targets: ["PanchangAlarm"],
            bundleIdentifier: "com.vineetbasantani.panchangalarm",
            teamIdentifier: nil, // set this in Xcode once you have a Developer account
            displayVersion: "1.0.0",
            bundleVersion: "1",
            appIcon: nil, // add an .xcassets AppIcon in Xcode later
            accentColor: nil,
            supportedDeviceFamilies: [.phone],
            supportedInterfaceOrientations: [.portrait]
            // NOTE: Info.plist keys this app needs (NSAlarmKitUsageDescription,
            // NSLocationWhenInUseUsageDescription is NOT needed since we only
            // use MKLocalSearchCompleter, not device location) should be added
            // via Xcode's target "Info" tab after opening this project — see
            // README "First-time Xcode setup" for the exact keys to add.
        )
    ],
    targets: [
        .executableTarget(
            name: "PanchangAlarm",
            path: "Sources/PanchangAlarm"
        ),
        .testTarget(
            name: "PanchangAlarmTests",
            dependencies: ["PanchangAlarm"],
            path: "Tests/PanchangAlarmTests"
        )
    ]
)
