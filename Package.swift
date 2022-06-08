// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MeshGradient",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13),
		.macCatalyst(.v13),
		.tvOS(.v13),
	],
    products: [
        .library(
            name: "MeshGradient",
            targets: ["MeshGradient"]),
		.library(name: "MeshGradientCHeaders",
				 targets: ["MeshGradientCHeaders"]),
    ],
    targets: [
        .target(
            name: "MeshGradient",
            dependencies: ["MeshGradientCHeaders"],
			resources: [.copy("DummyResources/")]
		),
		.target(name: "MeshGradientCHeaders"),
    ]
)
