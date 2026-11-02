// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EchoTheScrappyBot",
    defaultLocalization: "fr",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "EchoEngineKit",
            targets: ["EchoEngineKit"]
        )
    ],
    targets: [
        .target(
            name: "EchoEngineKit",
            path: "EchoTheScrappyBot",
            exclude: [
                "App/Info.plist",
                "Widget/EchoDeskWidget.swift"
            ],
            sources: [
                "Engine",
                "Audio",
                "Hardware",
                "Localization",
                "Persistence",
                "Views",
                "App"
            ],
            publicHeadersPath: "Engine",
            cxxSettings: [
                .headerSearchPath("Engine"),
                .unsafeFlags(["-std=c++20"])
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    ],
    cxxLanguageStandard: .cxx20
)
