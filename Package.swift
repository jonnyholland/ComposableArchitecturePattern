// swift-tools-version: 5.10
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
		.library(
			name: "Composable",
			targets: ["Composable"]
		),
		.executable(
			name: "ComposableClient",
			targets: ["ComposableClient"]
		),
    ],
    dependencies: [
		.package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2"),
    ],
    targets: [
		.macro(
			name: "ComposableMacros",
			dependencies: [
				.product(
					name: "SwiftSyntaxMacros",
					package: "swift-syntax"
				),
				.product(
					name: "SwiftCompilerPlugin",
					package: "swift-syntax"
				)
			]
		),
		
		.target(
			name: "Composable",
			dependencies: ["ComposableMacros"]
		),
		
		.executableTarget(
			name: "ComposableClient",
			dependencies: ["Composable"]
		),
		
		.target(
			name: "ComposableArchitecturePattern",
			dependencies: ["Composable"]
		),

        .testTarget(
            name: "ComposableArchitecturePatternTests",
            dependencies: [
                "ComposableMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
