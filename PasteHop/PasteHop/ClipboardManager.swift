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
            
            // Check for Image
            if let data = pasteboard.data(forType: .tiff) {
                let newItem = ClipboardItem(content: "Image", imageData: data, type: .image, format: .tiff)
                history.insert(newItem, at: 0)
                print("Clipboard captured: Image (TIFF)")
            } else if let data = pasteboard.data(forType: .png) {
                let newItem = ClipboardItem(content: "Image", imageData: data, type: .image, format: .png)
                history.insert(newItem, at: 0)
                print("Clipboard captured: Image (PNG)")
            }
            // Check for Text
            else if let str = pasteboard.string(forType: .string) {
                // Avoid duplicates if the last item is the same
                if let lastItem = history.first, lastItem.type == .text, lastItem.content == str {
                    return
                }
                
                let newItem = ClipboardItem(content: str, imageData: nil, type: .text, format: .string)
                history.insert(newItem, at: 0)
                print("Clipboard captured: \(str.prefix(20))...")
            }
            
            // Limit history size
            if history.count > 50 {
                history.removeLast()
            }
        }
    }
}

enum ClipboardItemType {
    case text
    case image
}

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let imageData: Data?
    let type: ClipboardItemType
    let format: NSPasteboard.PasteboardType
    let date = Date()
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}
