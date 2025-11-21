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
                handleNewClipboardItem(content: "Image", imageData: data, type: .image, format: .tiff)
            } else if let data = pasteboard.data(forType: .png) {
                handleNewClipboardItem(content: "Image", imageData: data, type: .image, format: .png)
            }
            // Check for Text
            else if let str = pasteboard.string(forType: .string) {
                let detectedType = detectTextType(str)
                handleNewClipboardItem(content: str, imageData: nil, type: detectedType, format: .string)
            }
        }
    }
    
    private func detectTextType(_ text: String) -> ClipboardItemType {
        // Trim whitespace for cleaner detection
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // URL detection
        let urlPattern = #"^(https?|ftp)://[^\s/$.?#].[^\s]*$"#
        if let _ = trimmed.range(of: urlPattern, options: .regularExpression) {
            return .url
        }
        
        // Code detection heuristics
        let codeIndicators = [
            text.contains("func "),
            text.contains("class "),
            text.contains("import "),
            text.contains("const "),
            text.contains("let "),
            text.contains("var "),
            text.contains("function "),
            text.contains("def "),
            text.contains("public "),
            text.contains("private "),
            text.contains("{") && text.contains("}"),
            text.contains("=>"),
            text.contains("//") || text.contains("/*"),
            text.range(of: #"^\s*(import|from|export|const|let|var|function|class|def|public|private)"#, options: .regularExpression) != nil
        ]
        
        // If 2 or more indicators are present, consider it code
        let indicatorCount = codeIndicators.filter { $0 }.count
        return indicatorCount >= 2 ? .code : .text
    }
    
    private func handleNewClipboardItem(content: String, imageData: Data?, type: ClipboardItemType, format: NSPasteboard.PasteboardType) {
        // Check if this exact item already exists in history
        if let existingIndex = history.firstIndex(where: { item in
            if type == .text || type == .code || type == .url {
                // For text/code/url, compare content
                return (item.type == .text || item.type == .code || item.type == .url) && item.content == content
            } else if type == .image, let newData = imageData, let existingData = item.imageData {
                // For images, compare data
                return item.type == .image && existingData == newData
            }
            return false
        }) {
            // Item already exists, move it to the top
            let existingItem = history.remove(at: existingIndex)
            history.insert(existingItem, at: 0)
            print("Moved existing item to top: \(content.prefix(20))...")
        } else {
            // New unique item, add it
            let newItem = ClipboardItem(content: content, imageData: imageData, type: type, format: format)
            history.insert(newItem, at: 0)
            print("Clipboard captured: \(content.prefix(20))...")
            
            // Limit history size to 5 items
            if history.count > 5 {
                history.removeLast()
            }
        }
    }
}

enum ClipboardItemType {
    case text
    case code
    case url
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
