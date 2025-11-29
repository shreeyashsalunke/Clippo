import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var menuViewModel: MenuViewModel
    
    init(_ popover: NSPopover, viewModel: MenuViewModel) {
        self.popover = popover
        self.menuViewModel = viewModel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clippo")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // Listen for close notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closePopover),
            name: Notification.Name("CloseMenuPopover"),
            object: nil
        )
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            // Update view model state before showing
            // This ensures dark mode toggle reflects current state if changed elsewhere
            menuViewModel.isDarkMode = ThemeManager.shared.isDarkMode
            
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            
            // Activate app to ensure popover receives events
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
}
