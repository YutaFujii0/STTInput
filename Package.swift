// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STTInput",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "STTInput", targets: ["STTInput"])
    ],
    targets: [
        .executableTarget(
            name: "STTInput",
            dependencies: [
                "InputMonitorKit",
                "OverlayUI",
                "AudioCaptureKit",
                "WhisperClient",
                "TextInjector"
            ]
        ),
        .target(
            name: "InputMonitorKit",
            dependencies: []
        ),
        .target(
            name: "OverlayUI",
            dependencies: []
        ),
        .target(
            name: "AudioCaptureKit",
            dependencies: []
        ),
        .target(
            name: "WhisperClient",
            dependencies: []
        ),
        .target(
            name: "TextInjector",
            dependencies: []
        )
    ]
)
