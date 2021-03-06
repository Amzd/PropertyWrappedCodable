// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PropertyWrappedCodable",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "PropertyWrappedCodable",
            targets: ["PropertyWrappedCodable"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/wickwirew/Runtime", from: "2.1.1"),
        // before breaking issues:
        .package(url: "https://github.com/Azoy/Echo", .revision("92d09d75e382cb7e4fd0ed02bca445d0d7958207"))
        // current:
//        .package(url: "https://github.com/Azoy/Echo", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "PropertyWrappedCodable",
            dependencies: []),
        .testTarget(
            name: "PropertyWrappedCodableTests",
            dependencies: ["PropertyWrappedCodable", "Runtime", "Echo"])
    ]
)
