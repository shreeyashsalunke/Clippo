import Foundation
import AppKit

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var history: [ClipboardItem] = []
    
    private var timer: Timer?
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    
    init() {
        self.lastChangeCount = pasteboard.changeCount
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            if let str = pasteboard.string(forType: .string) {
                // Avoid duplicates if the last item is the same
                if let lastItem = history.first, lastItem.content == str {
                    return
                }
                
                let newItem = ClipboardItem(content: str, type: .text)
                history.insert(newItem, at: 0)
                
                // Limit history size
                if history.count > 50 {
                    history.removeLast()
                }
                
                print("Clipboard captured: \(str.prefix(20))...")
            }
        }
    }
}

enum ClipboardItemType {
    case text
    case image // Placeholder for future
}

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let type: ClipboardItemType
    let date = Date()
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}
