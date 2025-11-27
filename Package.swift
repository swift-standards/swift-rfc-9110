// swift-tools-version: 6.2

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
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-3986", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-4648", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5322", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "RFC 9110",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "RFC 4648", package: "swift-rfc-4648"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(name: "Standards", package: "swift-standards")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "RFC 9110".tests,
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

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
