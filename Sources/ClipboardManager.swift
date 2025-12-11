import Foundation
import AppKit

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var history: [ClipboardItem] = []
    @Published var lastIgnoredReason: String? = nil
    
    private var timer: Timer?
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    
    init() {
        self.lastChangeCount = pasteboard.changeCount
        startMonitoring()
    }
    
    deinit {
        // Security: Clear clipboard history when manager is deallocated
        history.removeAll()
        timer?.invalidate()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            // Check if password protection is enabled
            let isPasswordProtectionEnabled = UserDefaults.standard.bool(forKey: "passwordProtectionEnabled")
            
            if isPasswordProtectionEnabled {
                // Get frontmost app for filtering
                let frontmostBundleID = PasswordDetector.getFrontmostAppBundleID()
                
                // Check if we should ignore based on source app
                if PasswordDetector.shouldIgnoreFromApp(frontmostBundleID) {
                    lastIgnoredReason = "Clippo ignores clipboard copies from password managers for your privacy."
                    print("Ignored clipboard from password manager: \(frontmostBundleID ?? "unknown")")
                    return
                }
            }
            
            // Check for Files/Folders FIRST (before images, because Finder provides both icon image and file URL)
            if let fileURLs = (pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL])?.filter({ $0.isFileURL }), !fileURLs.isEmpty {
                if fileURLs.count == 1 {
                    let url = fileURLs[0]
                    var isDir: ObjCBool = false
                    FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                    
                    if isDir.boolValue {
                        handleNewClipboardItem(content: url.lastPathComponent, imageData: nil, fileURLs: fileURLs, representations: nil, type: .folder, format: .fileURL)
                    } else {
                        handleNewClipboardItem(content: url.lastPathComponent, imageData: nil, fileURLs: fileURLs, representations: nil, type: .file, format: .fileURL)
                    }
                } else {
                    // Multiple items
                    let allFolders = fileURLs.allSatisfy { url in
                        var isDir: ObjCBool = false
                        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                        return isDir.boolValue
                    }
                    
                    if allFolders {
                        handleNewClipboardItem(content: "\(fileURLs.count) Folders", imageData: nil, fileURLs: fileURLs, representations: nil, type: .folders, format: .fileURL)
                    } else {
                        handleNewClipboardItem(content: "\(fileURLs.count) Files", imageData: nil, fileURLs: fileURLs, representations: nil, type: .files, format: .fileURL)
                    }
                }
            }
            // Check for Image
            else if let data = pasteboard.data(forType: .tiff) {
                let reps = getAllRepresentations()
                handleNewClipboardItem(content: "Image", imageData: data, fileURLs: nil, representations: reps, type: .image, format: .tiff)
            } else if let data = pasteboard.data(forType: .png) {
                let reps = getAllRepresentations()
                handleNewClipboardItem(content: "Image", imageData: data, fileURLs: nil, representations: reps, type: .image, format: .png)
            } else if let data = pasteboard.data(forType: .pdf) {
                // PDF support - treat as image for preview
                let reps = getAllRepresentations()
                handleNewClipboardItem(content: "PDF content", imageData: data, fileURLs: nil, representations: reps, type: .image, format: .pdf)
            }
            // Check for Text
            else if let str = pasteboard.string(forType: .string) {
                // Check if content looks like a password/secret (only if protection is enabled)
                if isPasswordProtectionEnabled && PasswordDetector.isLikelySecret(str) {
                    lastIgnoredReason = "Clippo ignores clipboard copies from password managers for your privacy."
                    print("Ignored password-like content: \(str.prefix(10))...")
                    return
                }
                
                let detectedType = detectTextType(str)
                let reps = getAllRepresentations()
                
                // Heuristic: If it's detected as plain text (not code/url), check if we have proprietary data.
                // If so, upgrade it to .other (Application Data) to preserve the rich context (like Figma layers).
                var finalType = detectedType
                if detectedType == .text {
                    let hasProprietaryData = pasteboard.types?.contains(where: { isProprietaryType($0) }) ?? false
                    if hasProprietaryData {
                        finalType = .other
                    }
                }
                
                // Capture source app for icon display
                let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                
                handleNewClipboardItem(content: str, imageData: nil, fileURLs: nil, representations: reps, sourceAppBundleID: sourceApp, type: finalType, format: .string)
            }
            // Fallback: Capture everything else
            else {
                var reps: [NSPasteboard.PasteboardType: Data] = [:]
                for type in pasteboard.types ?? [] {
                    if let data = pasteboard.data(forType: type) {
                        reps[type] = data
                    }
                }
                
                if !reps.isEmpty {
                    let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                    handleNewClipboardItem(content: "Data", imageData: nil, fileURLs: nil, representations: reps, sourceAppBundleID: sourceApp, type: .other, format: .string)
                }
            }
        }
    }
    
    private func getAllRepresentations() -> [NSPasteboard.PasteboardType: Data] {
        var reps: [NSPasteboard.PasteboardType: Data] = [:]
        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                reps[type] = data
            }
        }
        return reps
    }
    
    private func isProprietaryType(_ type: NSPasteboard.PasteboardType) -> Bool {
        let typeString = type.rawValue
        
        // Standard interchangeable types (allowlist)
        if typeString.hasPrefix("public.") || // public.utf8-plain-text, public.png, etc.
           typeString.hasPrefix("com.apple.") || // com.apple.webarchive, etc.
           typeString.hasPrefix("dyn.") || // Dynamic system types
           typeString == "NeXT RTFD pasteboard type" {
            return false
        }
        
        // Everything else is likely proprietary (e.g. com.figma.node, com.adobe.pdf, etc.)
        return true
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
    
    private func handleNewClipboardItem(content: String, imageData: Data?, fileURLs: [URL]?, representations: [NSPasteboard.PasteboardType: Data]?, sourceAppBundleID: String? = nil, type: ClipboardItemType, format: NSPasteboard.PasteboardType) {
        // Check if this exact item already exists in history
        if let existingIndex = history.firstIndex(where: { item in
            if type == .text || type == .code || type == .url {
                // For text/code/url, compare content
                return (item.type == .text || item.type == .code || item.type == .url) && item.content == content
            } else if type == .image, let newData = imageData, let existingData = item.imageData {
                // For images, compare data
                return item.type == .image && existingData == newData
            } else if (type == .file || type == .folder || type == .files || type == .folders), let newURLs = fileURLs, let existingURLs = item.fileURLs {
                // For files/folders, compare URLs
                return item.type == type && existingURLs == newURLs
            } else if type == .other, let newReps = representations, let existingReps = item.representations {
                // Strict check: Compare actual data to distinguish between different binary objects (e.g. diff Figma layers).
                // Do NOT revert to simple key checking as it causes data loss for rich content.
                return item.type == .other && newReps == existingReps
            }
            return false
        }) {
            // Item already exists, move it to the top
            let existingItem = history.remove(at: existingIndex)
            history.insert(existingItem, at: 0)
            
            #if DEBUG
            print("Moved existing item to top: \(type)")
            #endif
        } else {
            // New unique item, add it
            let newItem = ClipboardItem(content: content, imageData: imageData, fileURLs: fileURLs, representations: representations, sourceAppBundleID: sourceAppBundleID, type: type, format: format)
            history.insert(newItem, at: 0)
            
            // Security: Only log type and length, not actual content
            #if DEBUG
            print("Clipboard captured: \(type) (length: \(content.count))")
            #endif
            
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
    case file
    case folder
    case files // Multiple files
    case folders // Multiple folders
    case other
}

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let imageData: Data?
    let fileURLs: [URL]?
    let representations: [NSPasteboard.PasteboardType: Data]?
    let sourceAppBundleID: String?
    let type: ClipboardItemType
    let format: NSPasteboard.PasteboardType
    let date = Date()
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}
