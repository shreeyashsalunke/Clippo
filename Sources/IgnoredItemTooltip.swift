import SwiftUI
import AppKit

class TooltipWindowController: NSWindowController {
    convenience init(message: String) {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        self.init(window: window)
        
        // Use a simple NSView instead of NSHostingView to avoid Auto Layout issues
        let containerView = NSView(frame: window.contentView!.bounds)
        containerView.wantsLayer = true
        
        // Background with rounded corners
        let backgroundLayer = CALayer()
        backgroundLayer.frame = CGRect(x: 8, y: 8, width: 284, height: 44)
        backgroundLayer.backgroundColor = NSColor.black.withAlphaComponent(0.85).cgColor
        backgroundLayer.cornerRadius = 8
        backgroundLayer.shadowColor = NSColor.black.cgColor
        backgroundLayer.shadowOpacity = 0.3
        backgroundLayer.shadowRadius = 8
        backgroundLayer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer?.addSublayer(backgroundLayer)
        
        // Icon
        let iconImageView = NSImageView(frame: CGRect(x: 24, y: 20, width: 20, height: 20))
        iconImageView.image = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: nil)
        iconImageView.contentTintColor = .white
        containerView.addSubview(iconImageView)
        
        // Text
        let textField = NSTextField(frame: CGRect(x: 56, y: 16, width: 220, height: 28))
        textField.stringValue = message
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 13)
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 2
        containerView.addSubview(textField)
        
        window.contentView = containerView
        
        // Position near menu bar
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 320
            let y = screenFrame.maxY - 80
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    func show(duration: TimeInterval = 3.0) {
        window?.orderFront(nil)
        window?.alphaValue = 0
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window?.animator().alphaValue = 1.0
        }, completionHandler: {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.hide()
            }
        })
    }
    
    func hide() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window?.animator().alphaValue = 0
        }, completionHandler: {
            self.window?.orderOut(nil)
        })
    }
}

