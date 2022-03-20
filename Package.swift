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
            url: "https://github.com/CleverTap/CTSoftPhone/releases/download/0.0.3-alpha/CTSoftPhone.xcframework.zip",
            checksum: "6867cb2a806470bb3a6923332a1aaeb55cb8185c72bb5b6da737eb95ce670551"
        )
    ]
)
