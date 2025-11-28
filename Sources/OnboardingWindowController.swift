import Cocoa
import SwiftUI

class OnboardingWindowController: NSWindowController {
    private var hostingController: NSHostingController<OnboardingView>?
    private let onboardingState = OnboardingState()
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 524, height: 600),
            styleMask: [.borderless, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Clippo"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.center()
        
        self.init(window: window)
        
        // Setup the view
        let onboardingView = OnboardingView(onboardingState: onboardingState) { [weak self] in
            self?.close()
        }
        
        self.hostingController = NSHostingController(rootView: onboardingView)
        window.contentViewController = hostingController
    }
    
    func resetAndShow() {
        onboardingState.reset()
        showWindow(nil)
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }
}
