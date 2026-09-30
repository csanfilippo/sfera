// swift-tools-version: 6.4
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
    platforms: [.iOS(.v26), .macOS(.v26), .watchOS(.v26), .tvOS(.v26)],
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
            resources: privacyManifestResource
        ),
        .testTarget(
            name: "sferaTests",
            dependencies: ["sfera"]
        ),
    ]
)
