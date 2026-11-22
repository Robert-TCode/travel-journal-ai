// swift-tools-version: 6.4
import PackageDescription

// The app's visual language, with no knowledge of the journal's domain:
// tokens (palette, skies, type, spacing) and the components built from them.
let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v27)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    targets: [
        .target(name: "DesignSystem"),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
    ]
)
