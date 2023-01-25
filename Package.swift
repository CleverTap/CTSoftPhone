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
            url: "https://github.com/CleverTap/CTSoftPhone/releases/download/0.0.7-alpha/CTSoftPhone.xcframework.zip",
            checksum: "65c8b13eb1965f7074ae3b49afb1ee6b9a84337d20407827447592e69ebd6a1f"
        )
    ]
)
