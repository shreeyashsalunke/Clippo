import SwiftUI
import Carbon

struct SettingsView: View {
    @ObservedObject var hotKeyManager = HotKeyManager.shared
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Paste Shortcut")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Text(isRecording ? "Press keys..." : hotKeyManager.shortcutString)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isRecording ? 2 : 1)
                        )
                        .frame(minWidth: 120)
                    
                    Button(isRecording ? "Cancel" : "Edit") {
                        isRecording.toggle()
                    }
                }
                
                if !isRecording {
                    Button("Reset to Default") {
                        hotKeyManager.resetToDefault()
                    }
                    .controlSize(.small)
                    .foregroundColor(.secondary)
                }
            }
            
            Text("Press the key combination you want to use to paste items from Clippo.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(30)
        .frame(width: 350)
        .background(KeyRecorder(isRecording: $isRecording))
    }
}

struct KeyRecorder: NSViewRepresentable {
    @Binding var isRecording: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onKeyDown = { event in
            if isRecording {
                // Ignore standalone modifier keys
                // 54 = Right Command, 55 = Left Command, 56 = Left Shift, 57 = Caps Lock, 58 = Left Option, 59 = Left Control, 
                // 60 = Right Shift, 61 = Right Option, 62 = Right Control, 63 = Function
                let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
                if modifierKeyCodes.contains(event.keyCode) {
                    return false
                }
                
                // Convert NSEvent modifiers to Carbon modifiers
                var carbonModifiers: UInt32 = 0
                if event.modifierFlags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
                if event.modifierFlags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
                if event.modifierFlags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
                if event.modifierFlags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
                
                HotKeyManager.shared.updateHotKey(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers)
                isRecording = false
                return true // Handled
            }
            return false
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

class KeyView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if let onKeyDown = onKeyDown, onKeyDown(event) {
            return
        }
        super.keyDown(with: event)
    }
    
    // Also capture performKeyEquivalent for Cmd keys
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if let onKeyDown = onKeyDown, onKeyDown(event) {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
