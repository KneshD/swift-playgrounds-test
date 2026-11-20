// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WelcomeKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WelcomeKit",
            targets: ["WelcomeKit"]
        )
    ],
    targets: [
        .target(
            name: "WelcomeKit"
        )
    ]
)
