// swift-tools-version: 6.1
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
			targets: ["ComposableArchitecturePattern"]),
    ],
    dependencies: [
    ],
    targets: [
		.target(
			name: "ComposableArchitecturePattern",
			dependencies: []
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
