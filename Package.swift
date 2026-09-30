// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if canImport(Darwin)
let privacyManifestExclude: [String] = []
let privacyManifestResource: [PackageDescription.Resource] = [.copy("PrivacyInfo.xcprivacy")]
#else
let privacyManifestExclude: [String] = ["PrivacyInfo.xcprivacy"]
let privacyManifestResource: [PackageDescription.Resource] = []
#endif

let package = Package(
    name: "sfera",
    platforms: [.iOS(.v13), .macOS(.v13), .watchOS(.v8), .tvOS(.v13)],
    products: [
        .library(
            name: "sfera",
            targets: ["sfera"]
        ),
    ],
    targets: [
        .target(
            name: "sfera",
            exclude: privacyManifestExclude,
            resources: privacyManifestResource,
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "sferaTests",
            dependencies: ["sfera"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
