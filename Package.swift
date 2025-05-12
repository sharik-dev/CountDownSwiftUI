// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CountDownSwiftUI",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "CountDownSwiftUI",
            targets: ["CountDownSwiftUI"]),
    ],
    dependencies: [
        .package(path: "CountDownSwiftUI/DesignSystemKit")
    ],
    targets: [
        .target(
            name: "CountDownSwiftUI",
            dependencies: ["DesignSystemKit"]),
    ]
) 