// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clippo",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "Clippo",
            path: "Sources",
            sources: [
                "ClippoApp.swift",
                "ContentView.swift",
                "ClipboardManager.swift",
                "HotKeyManager.swift",
                "OverlayWindow.swift",
                "OnboardingView.swift",
                "OnboardingWindowController.swift",
                "OnboardingState.swift",
                "SettingsView.swift",
                "SettingsWindowController.swift",
                "PasswordDetector.swift",
                "IgnoredItemTooltip.swift",
                "MenuView.swift",
                "StatusBarController.swift",
                "ThemeManager.swift"
            ],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
