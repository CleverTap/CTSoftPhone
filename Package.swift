// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CTSoftPhone",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "CTSoftPhone",
            targets: ["CTSoftPhone"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "CTSoftPhone",
            url: "https://github.com/CleverTap/CTSoftPhone/releases/download/0.0.6-alpha/CTSoftPhone.xcframework.zip",
            checksum: "876f63714ed067b2e06baab7a55fb53d00f933fd00eb25bb3035bf69b042d3e5"
        )
    ]
)
