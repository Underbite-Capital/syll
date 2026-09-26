// swift-tools-version: 6.0
import Foundation
import PackageDescription

// Use the pinned commit by default. An existing checkout of that exact commit can
// be supplied for offline runs without changing the package or product source.
let fluidAudio: Package.Dependency
let fluidAudioIdentity: String
if let local = ProcessInfo.processInfo.environment["SYLL_FLUIDAUDIO_SOURCE"] {
    fluidAudio = .package(path: local)
    fluidAudioIdentity = URL(fileURLWithPath: local).lastPathComponent
} else {
    fluidAudio = .package(
        url: "https://github.com/FluidInference/FluidAudio.git",
        revision: "c7b13a3942e79893f3bd76bfe3b1ed8d03e0bfc7"
    )
    fluidAudioIdentity = "FluidAudio"
}

let package = Package(
    name: "SyllRecognitionEvaluation",
    platforms: [.macOS(.v14)],
    dependencies: [fluidAudio],
    targets: [
        .executableTarget(
            name: "syll-recognition-eval",
            dependencies: [.product(name: "FluidAudio", package: fluidAudioIdentity)]
        ),
    ]
)
