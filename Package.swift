// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorHelpscout",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapacitorHelpscout",
            targets: ["HelpScoutPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/helpscout/beacon-ios-sdk.git", from: "4.1.0")
    ],
    targets: [
        .target(
            name: "HelpScoutPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "Beacon-iOS", package: "beacon-ios-sdk")
            ],
            path: "ios/Sources/HelpScoutPlugin"),
        .testTarget(
            name: "HelpScoutPluginTests",
            dependencies: ["HelpScoutPlugin"],
            path: "ios/Tests/HelpScoutPluginTests")
    ]
)
