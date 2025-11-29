import SwiftUI
import Carbon
import Combine

@main
struct ClippoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

enum AppAppearance: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    
    var nsAppearance: NSAppearance? {
        switch self {
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: OverlayWindow!
    var hostingController: NSHostingController<ContentView>!
    var isPasting: Bool = false {
        didSet { updateView() }
    }
    
    var selectionIndex: Int = 0 {
        didSet { updateView() }
    }
    
    // Onboarding
    var onboardingWindowController: OnboardingWindowController?
    var settingsWindowController: SettingsWindowController?
    var tooltipWindowController: TooltipWindowController?
    
    private var cancellables = Set<AnyCancellable>()
    
    var isOnboardingComplete: Bool {
        UserDefaults.standard.bool(forKey: "onboardingComplete")
    }
    
    func updateView() {
        hostingController.rootView = ContentView(
            selectionIndex: Binding(get: { self.selectionIndex }, set: { self.selectionIndex = $0 }),
            isPasting: Binding(get: { self.isPasting }, set: { self.isPasting = $0 })
        )
    }
    
    var currentAppearance: AppAppearance {
        get {
            return ThemeManager.shared.isDarkMode ? .dark : .light
        }
        set {
            ThemeManager.shared.isDarkMode = (newValue == .dark)
        }
    }
    
    func applyAppearance() {
        // Force view update to pick up new appearance from ThemeManager
        if hostingController != nil {
            updateView()
        }
    }
    
    var statusBarController: StatusBarController?
    var popover: NSPopover!
    
    // Helper to create menu icon with specific sizing
    func createMenuIcon(systemName: String, size: CGFloat = 20) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
        return NSImage(systemSymbolName: systemName, accessibilityDescription: nil)?.withSymbolConfiguration(config)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check Accessibility Permissions
        checkAccessibilityPermissions()
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Setup UI
        let contentView = ContentView(
            selectionIndex: Binding(get: { self.selectionIndex }, set: { self.selectionIndex = $0 }),
            isPasting: Binding(get: { self.isPasting }, set: { self.isPasting = $0 })
        )
        hostingController = NSHostingController(rootView: contentView)
        
        overlayWindow = OverlayWindow()
        overlayWindow.contentViewController = hostingController
        overlayWindow.setFrame(NSRect(x: 0, y: 0, width: 1504, height: 420), display: true)
        overlayWindow.center()
        
        // Setup HotKey
        HotKeyManager.shared.onHotKeyTriggered = { [weak self] in
            self?.handleHotKey()
        }
        HotKeyManager.shared.setup()
        
        // Monitor flags for release
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
        
        // Setup Custom Menu Popover
        let menuViewModel = MenuViewModel()
        let menuView = MenuView(viewModel: menuViewModel)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 300) // Height will adjust dynamically but setting a base
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: menuView)
        // Make popover background transparent so VisualEffectView works
        popover.contentViewController?.view.window?.backgroundColor = .clear
        
        statusBarController = StatusBarController(popover, viewModel: menuViewModel)
        
        // Show onboarding if first launch
        if !isOnboardingComplete {
            showOnboarding()
        }
        
        // Observe clipboard ignored events
        ClipboardManager.shared.$lastIgnoredReason
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reason in
                self?.showTooltip(message: reason)
                // Reset after showing to prevent repeated triggers
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    ClipboardManager.shared.lastIgnoredReason = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility not enabled")
        }
    }
    
    func showOnboarding() {
        if onboardingWindowController == nil {
            onboardingWindowController = OnboardingWindowController()
        }
        onboardingWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func toggleAppearance() {
        currentAppearance = (currentAppearance == .light) ? .dark : .light
    }
    
    @objc func resetOnboarding() {
        if onboardingWindowController == nil {
            onboardingWindowController = OnboardingWindowController()
        }
        onboardingWindowController?.resetAndShow()
    }
    
    @objc func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.show()
    }
    
    func showTooltip(message: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showTooltip(message: message)
            }
            return
        }
        tooltipWindowController = TooltipWindowController(message: message)
        tooltipWindowController?.show()
    }
    
    @objc func clearHistory() {
        ClipboardManager.shared.history.removeAll()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    var hideTimer: Timer?
    
    func handleHotKey() {
        if !overlayWindow.isVisible {
            // Update window size before showing
            updateWindowFrame()
            
            // Show window
            selectionIndex = 0
            centerOverlayWindow()
            overlayWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            // Safety timeout: auto-hide after 10 seconds
            hideTimer?.invalidate()
            hideTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                self?.dismissOverlay()
            }
        } else {
            // Cycle selection
            let count = ClipboardManager.shared.history.count
            if count > 0 {
                selectionIndex = (selectionIndex + 1) % count
            }
        }
    }
    
    func updateWindowFrame() {
        let count = max(1, CGFloat(ClipboardManager.shared.history.count))
        let cardWidth: CGFloat = 256
        let spacing: CGFloat = 24
        let padding: CGFloat = 128 // 64 * 2
        
        let newWidth = (count * cardWidth) + ((count - 1) * spacing) + padding
        let newHeight: CGFloat = 420
        
        let currentFrame = overlayWindow.frame
        let newFrame = NSRect(x: currentFrame.minX, y: currentFrame.minY, width: newWidth, height: newHeight)
        
        overlayWindow.setFrame(newFrame, display: true)
    }
    
    func centerOverlayWindow() {
        // Get the screen that contains the mouse pointer
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = overlayWindow.frame
        
        // Calculate center position
        let x = screenFrame.midX - (windowFrame.width / 2)
        let y = screenFrame.midY - (windowFrame.height / 2)
        
        overlayWindow.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func handleFlagsChanged(_ event: NSEvent) {
        guard overlayWindow.isVisible else { return }
        
        // Check if BOTH Cmd AND Shift are released
        let hasCommand = event.modifierFlags.contains(.command)
        let hasShift = event.modifierFlags.contains(.shift)
        
        if !hasCommand || !hasShift {
            if isPasting { return }
            
            // Trigger animation
            isPasting = true
            
            // Wait for animation then paste
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.pasteSelected()
                self.isPasting = false
            }
        }
    }
    
    func dismissOverlay() {
        hideTimer?.invalidate()
        hideTimer = nil
        
        if overlayWindow.isVisible {
            overlayWindow.orderOut(nil)
        }
    }
    
    func pasteSelected() {
        // Cancel the safety timer
        hideTimer?.invalidate()
        hideTimer = nil
        
        // 1. Get selected item
        let history = ClipboardManager.shared.history
        guard history.indices.contains(selectionIndex) else {
            overlayWindow.orderOut(nil)
            return
        }
        
        let item = history[selectionIndex]
        
        // 2. Put it on pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if item.type == .image, let data = item.imageData {
            pasteboard.setData(data, forType: item.format)
        } else {
            pasteboard.setString(item.content, forType: .string)
        }
        
        // 3. Hide window
        overlayWindow.orderOut(nil)
        NSApp.hide(nil) // Return focus to previous app
        
        // 4. Simulate Cmd+V if we have permission
        if AXIsProcessTrusted() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.simulatePaste()
            }
        } else {
            print("Accessibility permission missing. Item copied to clipboard but not pasted.")
        }
    }
    
    func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let vKeyCode: CGKeyCode = 9 // 'V'
        
        // Cmd down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true) // 0x37 is Cmd
        cmdDown?.flags = .maskCommand
        
        // V down
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        vDown?.flags = .maskCommand
        
        // V up
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        vUp?.flags = .maskCommand
        
        // Cmd up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
    
    @objc func openSystemSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}



