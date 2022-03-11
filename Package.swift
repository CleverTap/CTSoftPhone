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
            checksum: "8eb555e9095a37af1209d148889b1c57fbfa2b052a50e03ba764ffd71dca517e"
        )
    ]
)
