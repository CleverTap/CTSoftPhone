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
            url: "https://github.com/CleverTap/CTSoftPhone/releases/download/0.0.1-alpha/CTSoftPhone.xcframework.zip",
            checksum: "953ac142ce06cf0df2fcbe19e2b9381c426380001a6a762eb12f4b3021933c65"
        )
    ]
)
