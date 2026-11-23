// swift-tools-version: 6.4
import PackageDescription

// Clean Architecture layers as separate modules, so the compiler enforces
// the dependency rule: Presentation -> Domain <- DataLayer.
// The app target is the composition root and the only place that sees all three.
let package = Package(
    name: "TravelJournalKit",
    platforms: [.iOS(.v27)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "DataLayer", targets: ["DataLayer"]),
        .library(name: "Presentation", targets: ["Presentation"]),
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
    ],
    targets: [
        // Pure Swift. No Apple frameworks beyond Foundation (no FoundationModels, PhotoKit, MapKit...).
        .target(name: "Domain"),
        // Repositories and data sources: persistence, location, weather, Spotlight, language models.
        .target(name: "DataLayer", dependencies: ["Domain"]),
        // SwiftUI views and view models. Knows Domain and the design system.
        .target(name: "Presentation", dependencies: ["Domain", .product(name: "DesignSystem", package: "DesignSystem")]),

        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "DataLayerTests", dependencies: ["DataLayer"]),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation", .product(name: "DesignSystem", package: "DesignSystem")]),
    ]
)
