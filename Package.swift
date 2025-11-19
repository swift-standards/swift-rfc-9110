// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-rfc-9110",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "RFC 9110",
            targets: ["RFC 9110"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),
        .package(path: "../swift-incits-4-1986"),
        .package(path: "../swift-rfc-3986"),
        .package(path: "../swift-rfc-4648"),
        .package(path: "../swift-rfc-5322"),
        .package(path: "../swift-standards")
    ],
    targets: [
        .target(
            name: "RFC 9110",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "RFC_4648", package: "swift-rfc-4648"),
                .product(name: "RFC_5322", package: "swift-rfc-5322"),
                .product(name: "Standards", package: "swift-standards")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "RFC 9110 Tests",
            dependencies: ["RFC 9110"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(
        .enableUpcomingFeature("MemberImportVisibility")
    )
    target.swiftSettings = settings
}
