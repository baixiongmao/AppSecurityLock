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
            // 目标名要跟 podspec 里的 s.name 保持一致，Flutter 工具靠这个名字识别插件。
            // 不再手写 path/sources 指到包根目录之外（这是之前报错的原因：
            // "target 'app_security_lock' in package 'app_security_lock-0.3.5' is outside the package root"，
            // SPM 不允许 target 的源码目录跑到 Package.swift 所在目录（包根）之外）。
            // 直接用 SPM 默认约定 Sources/<target name>/ 即可，源码见 ./Sources/app_security_lock/。
            name: "app_security_lock"
        )
    ]
)
