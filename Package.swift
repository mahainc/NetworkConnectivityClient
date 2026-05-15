// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NetworkConnectivityClient",
    platforms: [
        .iOS(.v17), .macOS(.v14),
    ],
    products: [
        .singleTargetLibrary("NetworkConnectivityClient"),
        .singleTargetLibrary("NetworkConnectivityClientLive"),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "NetworkConnectivityClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "NetworkConnectivityClientLive",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "NetworkConnectivityClient",
            ]
        ),
        .testTarget(
            name: "NetworkConnectivityClientTests",
            dependencies: [
                "NetworkConnectivityClient",
            ]
        ),
    ]
)

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
