// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "app_security_lock",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "app_security_lock",
            targets: ["app_security_lock"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .target(
            name: "app_security_lock",
            dependencies: [],
            path: "..",
            sources: [
                "Classes"
            ],
            publicHeadersPath: "Classes"
        )
    ]
)
