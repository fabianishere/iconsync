// swift-tools-version:5.0

import PackageDescription

let package = Package(
        name: "iconsync",
        platforms: [
            // specify each minimum deployment requirement,
            //otherwise the platform default minimum is used.
            .macOS(.v10_11),
        ],
        dependencies: [
            .package(url: "https://github.com/kylef/Commander.git", from: "0.9.1"),
        ],
        targets: [
            // Targets are the basic building blocks of a package. A target can define a module or a test suite.
            // Targets can depend on other targets in this package, and on products in packages which this package depends on.
            .target(name: "iconsync",
                    dependencies: ["Commander"])
        ]
)
