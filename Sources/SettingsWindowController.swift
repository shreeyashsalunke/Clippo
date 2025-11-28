import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {
    private var hostingController: NSHostingController<SettingsView>?
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Clippo Settings"
        window.center()
        
        self.init(window: window)
        
        let settingsView = SettingsView()
        self.hostingController = NSHostingController(rootView: settingsView)
        window.contentViewController = hostingController
    }
    
    func show() {
        showWindow(nil)
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }
}
