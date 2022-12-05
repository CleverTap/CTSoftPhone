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
            checksum: "a19607df9f52478937ae4b333371a0e1bb306db9a2fd2fdb71d257f1a3a3887c"
        )
    ]
)
