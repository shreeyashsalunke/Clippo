import SwiftUI
import AppKit

protocol OverlayWindowDelegate: AnyObject {
    func navigateNext()
    func navigatePrevious()
}

class OverlayWindow: NSPanel {
    weak var overlayDelegate: OverlayWindowDelegate?

    init() {
        super.init(contentRect: .zero,
                   styleMask: [.nonactivatingPanel, .borderless],
                   backing: .buffered,
                   defer: false)
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
        self.isOpaque = false  // Critical for transparency!
        self.hasShadow = true
        self.isReleasedWhenClosed = false
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 124 { // Right Arrow
            overlayDelegate?.navigateNext()
        } else if event.keyCode == 123 { // Left Arrow
            overlayDelegate?.navigatePrevious()
        } else {
            super.keyDown(with: event)
        }
    }
}
