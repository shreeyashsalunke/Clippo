import Foundation
import Carbon
import AppKit

class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    var onHotKeyTriggered: (() -> Void)?
    
    @Published var shortcutString: String = ""
    
    private let defaultKeyCode = UInt32(kVK_ANSI_V)
    private let defaultModifiers = UInt32(cmdKey | shiftKey)
    
    init() {
        updateShortcutString()
    }
    
    func setup() {
        registerHotKey()
        installEventHandler()
    }
    
    func updateHotKey(keyCode: UInt32, modifiers: UInt32) {
        unregisterHotKey()
        
        UserDefaults.standard.set(Int(keyCode), forKey: "hotkey_keyCode")
        UserDefaults.standard.set(Int(modifiers), forKey: "hotkey_modifiers")
        UserDefaults.standard.set(true, forKey: "hotkey_customized")
        
        registerHotKey()
        updateShortcutString()
    }
    
    func resetToDefault() {
        unregisterHotKey()
        
        UserDefaults.standard.removeObject(forKey: "hotkey_keyCode")
        UserDefaults.standard.removeObject(forKey: "hotkey_modifiers")
        UserDefaults.standard.removeObject(forKey: "hotkey_customized")
        
        registerHotKey()
        updateShortcutString()
    }
    
    private func unregisterHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    private func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x50484F50) // 'PHOP'
        hotKeyID.id = 1
        
        let keyCode: UInt32
        let modifiers: UInt32
        
        if UserDefaults.standard.bool(forKey: "hotkey_customized") {
            keyCode = UInt32(UserDefaults.standard.integer(forKey: "hotkey_keyCode"))
            modifiers = UInt32(UserDefaults.standard.integer(forKey: "hotkey_modifiers"))
        } else {
            keyCode = defaultKeyCode
            modifiers = defaultModifiers
        }
        
        let status = RegisterEventHotKey(keyCode,
                                         modifiers,
                                         hotKeyID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &hotKeyRef)
        
        if status != noErr {
            print("Failed to register hotkey: \(status)")
        }
    }
    
    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            DispatchQueue.main.async {
                HotKeyManager.shared.onHotKeyTriggered?()
            }
            return noErr
        }, 1, &eventType, nil, &eventHandler)
    }
    
    private func updateShortcutString() {
        let keyCode: UInt32
        let modifiers: UInt32
        
        if UserDefaults.standard.bool(forKey: "hotkey_customized") {
            keyCode = UInt32(UserDefaults.standard.integer(forKey: "hotkey_keyCode"))
            modifiers = UInt32(UserDefaults.standard.integer(forKey: "hotkey_modifiers"))
        } else {
            keyCode = defaultKeyCode
            modifiers = defaultModifiers
        }
        
        var parts: [String] = []
        if (modifiers & UInt32(cmdKey)) != 0 { parts.append("⌘") }
        if (modifiers & UInt32(shiftKey)) != 0 { parts.append("⇧") }
        if (modifiers & UInt32(optionKey)) != 0 { parts.append("⌥") }
        if (modifiers & UInt32(controlKey)) != 0 { parts.append("⌃") }
        
        // Convert key code to string (simplified)
        // In a real app we'd use TISCopyCurrentKeyboardInputSource to get the actual character
        // For now, we'll map common keys or just use the key code if unknown
        let keyString = keyString(for: keyCode)
        parts.append(keyString)
        
        shortcutString = parts.joined(separator: "")
    }
    
    func getCurrentShortcut() -> (keyCode: UInt32, modifiers: UInt32) {
        if UserDefaults.standard.bool(forKey: "hotkey_customized") {
            return (
                UInt32(UserDefaults.standard.integer(forKey: "hotkey_keyCode")),
                UInt32(UserDefaults.standard.integer(forKey: "hotkey_modifiers"))
            )
        }
        return (defaultKeyCode, defaultModifiers)
    }
    
    private func keyString(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_Equal: return "="
        case kVK_ANSI_9: return "9"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_Minus: return "-"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_LeftBracket: return "["
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_Quote: return "\""
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_Semicolon: return ";"
        case kVK_ANSI_Backslash: return "\\"
        case kVK_ANSI_Comma: return ","
        case kVK_ANSI_Slash: return "/"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_Period: return "."
        case kVK_ANSI_Grave: return "`"
        case kVK_ANSI_KeypadDecimal: return "."
        case kVK_ANSI_KeypadMultiply: return "*"
        case kVK_ANSI_KeypadPlus: return "+"
        case kVK_ANSI_KeypadClear: return "Clear"
        case kVK_ANSI_KeypadDivide: return "/"
        case kVK_ANSI_KeypadEnter: return "Enter"
        case kVK_ANSI_KeypadMinus: return "-"
        case kVK_ANSI_KeypadEquals: return "="
        case kVK_ANSI_Keypad0: return "0"
        case kVK_ANSI_Keypad1: return "1"
        case kVK_ANSI_Keypad2: return "2"
        case kVK_ANSI_Keypad3: return "3"
        case kVK_ANSI_Keypad4: return "4"
        case kVK_ANSI_Keypad5: return "5"
        case kVK_ANSI_Keypad6: return "6"
        case kVK_ANSI_Keypad7: return "7"
        case kVK_ANSI_Keypad8: return "8"
        case kVK_ANSI_Keypad9: return "9"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Space: return "Space"
        case kVK_Delete: return "Delete"
        case kVK_Escape: return "Esc"
        case kVK_Command: return "Cmd"
        case kVK_Shift: return "Shift"
        case kVK_CapsLock: return "CapsLock"
        case kVK_Option: return "Option"
        case kVK_Control: return "Ctrl"
        case kVK_RightShift: return "Shift"
        case kVK_RightOption: return "Option"
        case kVK_RightControl: return "Ctrl"
        case kVK_Function: return "Fn"
        case kVK_F17: return "F17"
        case kVK_VolumeUp: return "VolUp"
        case kVK_VolumeDown: return "VolDown"
        case kVK_Mute: return "Mute"
        case kVK_F18: return "F18"
        case kVK_F19: return "F19"
        case kVK_F20: return "F20"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F3: return "F3"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F11: return "F11"
        case kVK_F13: return "F13"
        case kVK_F16: return "F16"
        case kVK_F14: return "F14"
        case kVK_F10: return "F10"
        case kVK_F12: return "F12"
        case kVK_F15: return "F15"
        case kVK_Help: return "Help"
        case kVK_Home: return "Home"
        case kVK_PageUp: return "PgUp"
        case kVK_ForwardDelete: return "Del"
        case kVK_F4: return "F4"
        case kVK_End: return "End"
        case kVK_F2: return "F2"
        case kVK_PageDown: return "PgDn"
        case kVK_F1: return "F1"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_DownArrow: return "↓"
        case kVK_UpArrow: return "↑"
        default: return "?"
        }
    }
}

