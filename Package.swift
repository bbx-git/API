// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "wpscan-register",
    products: [
        .executable(name: "wpscan-register", targets: ["WPScanRegister"])
    ],
    targets: [
        .executableTarget(
            name: "WPScanRegister",
            path: "."
        )
    ]
)
