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
            
            // Capture state on main thread
            let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            let isPasswordProtectionEnabled = UserDefaults.standard.bool(forKey: "passwordProtectionEnabled")
            
            // Move heavy operations to background thread to prevent UI blocking
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                let pasteboard = NSPasteboard.general
                
                // Check password protection
                if isPasswordProtectionEnabled {
                    if PasswordDetector.shouldIgnoreFromApp(sourceApp) {
                        DispatchQueue.main.async {
                            self.lastIgnoredReason = "Clippo ignores clipboard copies from password managers for your privacy."
                        }
                        print("Ignored clipboard from password manager: \(sourceApp ?? "unknown")")
                        return
                    }
                }
                
                // Capture ALL representations (heavy operation)
                var allRepresentations: [NSPasteboard.PasteboardType: Data] = [:]
                if let types = pasteboard.types {
                    for type in types {
                        if let data = pasteboard.data(forType: type) {
                            allRepresentations[type] = data
                        }
                    }
                }
                
                // Determine type and content
                if let fileURLs = (pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL])?.filter({ $0.isFileURL }), !fileURLs.isEmpty {
                    if fileURLs.count == 1 {
                        let url = fileURLs[0]
                        var isDir: ObjCBool = false
                        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                        
                        DispatchQueue.main.async {
                            if isDir.boolValue {
                                self.handleNewClipboardItem(content: url.lastPathComponent, imageData: nil, fileURLs: fileURLs, representations: allRepresentations, sourceAppBundleID: sourceApp, type: .folder, format: .fileURL)
                            } else {
                                self.handleNewClipboardItem(content: url.lastPathComponent, imageData: nil, fileURLs: fileURLs, representations: allRepresentations, sourceAppBundleID: sourceApp, type: .file, format: .fileURL)
                            }
                        }
                    } else {
                        let allFolders = fileURLs.allSatisfy { url in
                            var isDir: ObjCBool = false
                            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                            return isDir.boolValue
                        }
                        
                        DispatchQueue.main.async {
                            if allFolders {
                                self.handleNewClipboardItem(content: "\(fileURLs.count) Folders", imageData: nil, fileURLs: fileURLs, representations: allRepresentations, sourceAppBundleID: sourceApp, type: .folders, format: .fileURL)
                            } else {
                                self.handleNewClipboardItem(content: "\(fileURLs.count) Files", imageData: nil, fileURLs: fileURLs, representations: allRepresentations, sourceAppBundleID: sourceApp, type: .files, format: .fileURL)
                            }
                        }
                    }
                }
                else if let data = pasteboard.data(forType: .tiff) {
                    DispatchQueue.main.async {
                        self.handleNewClipboardItem(content: "Image", imageData: data, fileURLs: nil, representations: allRepresentations, sourceAppBundleID: sourceApp, type: .image, format: .tiff)
                    }
                } else if let data = pasteboard.data(forType: .png) {
                    DispatchQueue.main.async {
                        self.handleNewClipboardItem(content: "Image", imageData: data, fileURLs: nil, representations: allRepresentations, sourceAppBundleID: sourceApp, type: .image, format: .png)
                    }
                }
                else if let str = pasteboard.string(forType: .string) {
                    if isPasswordProtectionEnabled && PasswordDetector.isLikelySecret(str) {
                        DispatchQueue.main.async {
                            self.lastIgnoredReason = "Clippo ignores clipboard copies from password managers for your privacy."
                        }
                        print("Ignored password-like content: \(str.prefix(10))...")
                        return
                    }
                    
                    let textTypes: Set<String> = ["public.utf8-plain-text", "NSStringPboardType", "public.text"]
                    let hasRichData = allRepresentations.keys.contains { !textTypes.contains($0.rawValue) }
                    
                    if hasRichData {
                        DispatchQueue.main.async {
                            self.handleNewClipboardItem(content: str, imageData: nil, fileURLs: nil, representations: allRepresentations, sourceAppBundleID: sourceApp, type: .other, format: .string)
                        }
                    } else {
                        let detectedType = self.detectTextType(str)
                        DispatchQueue.main.async {
                            self.handleNewClipboardItem(content: str, imageData: nil, fileURLs: nil, representations: allRepresentations, sourceAppBundleID: sourceApp, type: detectedType, format: .string)
                        }
                    }
                }
                else {
                    if !allRepresentations.isEmpty {
                        DispatchQueue.main.async {
                            self.handleNewClipboardItem(content: "Data", imageData: nil, fileURLs: nil, representations: allRepresentations, sourceAppBundleID: sourceApp, type: .other, format: .string)
                        }
                    }
                }
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
                // For other, compare actual data to ensure we don't ignore different items with same types (e.g. different Figma layers)
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
