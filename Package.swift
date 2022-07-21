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
            url: "https://github.com/CleverTap/CTSoftPhone/releases/download/0.0.4-alpha/CTSoftPhone.xcframework.zip",
            checksum: "171a4838953f3b713c4a75b7cf94072f4da6fb7da0090f6704cc068026011a79"
        )
    ]
)
