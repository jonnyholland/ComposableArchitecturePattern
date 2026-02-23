// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "ComposableArchitecturePattern",
    platforms: [
		.iOS(.v17),
		.macOS(.v14),
		.tvOS(.v17),
		.watchOS(.v10),
		.macCatalyst(.v13)
	],
    products: [
		.library(
			name: "ComposableArchitecturePattern",
			targets: ["ComposableArchitecturePattern"]
		),
		.library(
			name: "CAP",
			targets: ["ComposableArchitecturePattern"]
		),
    ],
    dependencies: [
		.package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.24.0"),
    ],
    targets: [
		.target(
			name: "ComposableArchitecturePattern",
			dependencies: [
				.product(name: "Logging", package: "swift-log"),
				.product(name: "AsyncHTTPClient", package: "async-http-client", condition: .when(platforms: [.macOS, .linux])),
			]
		),
        .testTarget(
            name: "ComposableArchitecturePatternTests",
            dependencies: [
				"ComposableArchitecturePattern",
			],
			resources: [
				.process("Mock/JSON")
			]
        ),
    ]
)
