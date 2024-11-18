// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CTSoftPhone",
    platforms: [
        .iOS(.v12)
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
            url: "https://github.com/CleverTap/CTSoftPhone/releases/download/0.0.7-alpha/CTSoftPhone.xcframework.zip",
            checksum: "0e8e610031a4cf19a7816c0270bf6ce4610497523f593c1c38a0c938fd61d3e4"
        )
    ]
)
