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
            url: "https://github.com/CleverTap/CTSoftPhone/releases/download/0.0.2-alpha/CTSoftPhone.xcframework.zip",
            checksum: "79521ec9136a82a579c9bad89c0fc59b3d6cc144bcfa8676a4bb45a12d5ded9a"
        )
    ]
)
