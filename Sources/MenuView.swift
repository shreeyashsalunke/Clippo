import SwiftUI
import Combine

struct MenuView: View {
    @ObservedObject var viewModel: MenuViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            // Header
            MenuButton(
                title: "How it works",
                icon: "info.circle",
                action: viewModel.openOnboarding
            )
            
            Divider()
                .padding(.vertical, 4)
            
            // Settings Header
            HStack {
                Text("Settings")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
            
            // Settings Items
            MenuButton(
                title: "Clear History",
                icon: "trash",
                action: viewModel.clearHistory
            )
            
            MenuButton(
                title: viewModel.isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
                icon: viewModel.isDarkMode ? "sun.max" : "moon",
                action: viewModel.toggleAppearance
            )
            
            MenuButton(
                title: "Change Hotkey",
                icon: "keyboard",
                action: viewModel.openSettings
            ) {
                HStack(spacing: 2) {
                    ForEach(viewModel.shortcutParts, id: \.self) { part in
                        Text(part)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            // Privacy Toggle
            ToggleMenuButton(
                title: "Ignore Sensitive Content",
                subtitle: "Experimental",
                icon: "eye.slash",
                isOn: $viewModel.isPasswordProtectionEnabled
            )
            
            Divider()
                .padding(.vertical, 4)
            
            // Footer
            MenuButton(
                title: "Quit Clippo",
                icon: "xmark.circle", // Using xmark.circle as a close/quit icon
                action: viewModel.quitApp
            )
        }
        .padding(.vertical, 8)
        .frame(width: 260)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
}

struct MenuButton<Trailing: View>: View {
    let title: String
    let icon: String
    let action: () -> Void
    let trailing: () -> Trailing
    
    @State private var isHovered = false
    
    init(title: String, icon: String, action: @escaping () -> Void, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.icon = icon
        self.action = action
        self.trailing = trailing
    }
    
    init(title: String, icon: String, action: @escaping () -> Void) where Trailing == EmptyView {
        self.title = title
        self.icon = icon
        self.action = action
        self.trailing = { EmptyView() }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 16)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                Spacer()
                
                trailing()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)
        .padding(.horizontal, 6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ToggleMenuButton: View {
    let title: String
    let subtitle: String?
    let icon: String
    @Binding var isOn: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 16)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .scaleEffect(0.7)
                .focusable(false)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isHovered ? Color.primary.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .padding(.horizontal, 6)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            isOn.toggle()
        }
    }
}

class MenuViewModel: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var isPasswordProtectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isPasswordProtectionEnabled, forKey: "passwordProtectionEnabled")
        }
    }
    @Published var shortcutParts: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.isPasswordProtectionEnabled = UserDefaults.standard.bool(forKey: "passwordProtectionEnabled")
        // Initialize dark mode state based on current appearance
        if let rawValue = UserDefaults.standard.string(forKey: "appAppearance"),
           let appearance = AppAppearance(rawValue: rawValue) {
            self.isDarkMode = appearance == .dark
        }
        
        // Observe HotKey changes
        HotKeyManager.shared.$shortcutString
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newString in
                self?.updateShortcutParts(using: newString)
            }
            .store(in: &cancellables)
        
        updateShortcutParts(using: HotKeyManager.shared.shortcutString)
    }
    
    private func updateShortcutParts(using raw: String) {
        // Parse the shortcut string into parts for display
        // This is a heuristic since HotKeyManager joins them. 
        // Ideally HotKeyManager would expose parts, but we can split by known symbols or just characters.
        // Given the current HotKeyManager implementation, it joins symbols and then the key.
        // We'll just split the string into characters for now as most modifiers are single chars.
        // The last part might be multiple chars (e.g. "Space"), so we need to be careful.
        
        var parts: [String] = []
        
        // Known modifiers
        let modifiers = Set(["⌘", "⇧", "⌥", "⌃"])
        
        // Simple parsing: if char is a modifier, add as separate part. 
        // If not, accumulate (for keys like "Esc" or "Tab" or simple letters).
        // However, HotKeyManager puts modifiers first.
        
        // Let's try to reconstruct from HotKeyManager logic if possible, or just use the string.
        // The design shows separate boxes.
        // Let's just use the characters for modifiers, and the rest as the key.
        
        var remaining = raw
        
        while let first = remaining.first, modifiers.contains(String(first)) {
            parts.append(String(first))
            remaining.removeFirst()
        }
        
        if !remaining.isEmpty {
            parts.append(remaining)
        }
        
        self.shortcutParts = parts
    }
    
    func openOnboarding() {
        NSApp.sendAction(#selector(AppDelegate.resetOnboarding), to: nil, from: nil)
        closePopover()
    }
    
    func clearHistory() {
        NSApp.sendAction(#selector(AppDelegate.clearHistory), to: nil, from: nil)
        closePopover()
    }
    
    func toggleAppearance() {
        isDarkMode.toggle()
        let appearance: AppAppearance = isDarkMode ? .dark : .light
        UserDefaults.standard.set(appearance.rawValue, forKey: "appAppearance")
        
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.applyAppearance()
        }
    }
    
    func openSettings() {
        NSApp.sendAction(#selector(AppDelegate.openSettings), to: nil, from: nil)
        closePopover()
    }
    
    func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func closePopover() {
        NotificationCenter.default.post(name: Notification.Name("CloseMenuPopover"), object: nil)
    }
}


