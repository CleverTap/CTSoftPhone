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
            url: "https://github.com/CleverTap/CTSoftPhone/releases/download/0.0.5-alpha/CTSoftPhone.xcframework.zip",
            checksum: "35ea9cfcfb78e5739edf1fbd7ec092757d2bab6c079d236745ee019c65be81cc"
        )
    ]
)
