// swift-tools-version: 6.2
import PackageDescription

// Runs on the Mac: the on-device model there is the same family as on iPhone, and iterating is much faster.
let package = Package(
    name: "PromptLab",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "PromptLab"),
    ]
)
