// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "app_security_lock",
    // 代码里大量用到 UIWindowScene / connectedScenes（iOS 13+ 的 UIScene API），
    // podspec 里 `s.platform = :ios, '13.0'` 也是这么写的，这里要和它保持一致，
    // 不然 SPM 按更低的部署目标编译会报 "'UIWindowScene' is only available in iOS 13.0 or newer"。
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Flutter 生成的 FlutterGeneratedPluginSwiftPackage 会按照
        // 「Dart 包名中的下划线换成短横线」这个约定去引用 product，
        // 所以这里 library 的 name 必须是 "app-security-lock"（带短横线），
        // 不能直接照抄 Dart 包名 "app_security_lock"（下划线）。
        // 否则会报：
        // "product 'app-security-lock' required by package 'fluttergeneratedpluginswiftpackage' ...
        //  not found in package 'app_security_lock'."
        .library(
            name: "app-security-lock",
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
