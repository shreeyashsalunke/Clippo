// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PasteHop",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "PasteHop",
            path: "PasteHop",
            sources: [
                "PasteHopApp.swift",
                "ContentView.swift",
                "ClipboardManager.swift",
                "HotKeyManager.swift",
                "OverlayWindow.swift",
                "OnboardingView.swift",
                "OnboardingWindowController.swift",
                "OnboardingState.swift"
            ]
        )
    ]
)
