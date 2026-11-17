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
    targets: [
        // Pure Swift. No Apple frameworks beyond Foundation (no FoundationModels, PhotoKit, MapKit...).
        .target(name: "Domain"),
        // Repositories and data sources: Photos, MapKit, Contacts, Spotlight, language models.
        .target(name: "DataLayer", dependencies: ["Domain"]),
        // SwiftUI views and view models. Knows Domain only.
        .target(name: "Presentation", dependencies: ["Domain"]),

        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "DataLayerTests", dependencies: ["DataLayer"]),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation"]),
    ]
)
