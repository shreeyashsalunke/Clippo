import Foundation
import Carbon
import AppKit

class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    var onHotKeyTriggered: (() -> Void)?
    
    func setup() {
        registerHotKey()
        installEventHandler()
    }
    
    private func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x50484F50) // 'PHOP'
        hotKeyID.id = 1
        
        // Cmd + Shift + V
        // V key code is 9 (kVK_ANSI_V)
        let modifiers = cmdKey | shiftKey
        
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_V),
                                         UInt32(modifiers),
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
}

