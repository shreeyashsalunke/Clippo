import SwiftUI

struct ContentView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @Binding var selectionIndex: Int
    
    var body: some View {
        VStack(spacing: 24) {
            // Card Grid
            if clipboardManager.history.isEmpty {
                EmptyStateView()
            } else {
                HStack(spacing: 24) {
                    ForEach(Array(clipboardManager.history.enumerated()), id: \.element.id) { index, item in
                        ClipboardCard(
                            item: item,
                            isSelected: index == selectionIndex,
                            showPasteButton: index == selectionIndex
                        )
                        .onTapGesture {
                            selectionIndex = index
                        }
                    }
                }
            }
            
            // Footer: Keyboard Instructions
            HStack(spacing: 8) {
                Text("Press")
                    .instructionText()
                KeyBadge(text: "v")
                Text("while pressing")
                    .instructionText()
                KeyBadge(text: "⌘")
                KeyBadge(text: "⇧")
                Text("to hop to next")
                    .instructionText()
            }
        }
        .padding(.horizontal, 64)
        .padding(.vertical, 48)
        .frame(width: calculateWidth(), height: 420)
        .background(
            ZStack {
                // Backdrop blur
                BlurView(radius: 12)
                
                // Semi-transparent white overlay
                Color.white.opacity(0.6)
            }
        )
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 8)
    }
    
    private func calculateWidth() -> CGFloat {
        let count = max(1, CGFloat(clipboardManager.history.count))
        let cardWidth: CGFloat = 256
        let spacing: CGFloat = 24
        let padding: CGFloat = 128 // 64 * 2
        
        return (count * cardWidth) + ((count - 1) * spacing) + padding
    }
}

struct BlurView: NSViewRepresentable {
    let radius: CGFloat
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .menu  // Changed from .hudWindow for better transparency
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 24
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = .menu
        nsView.blendingMode = .behindWindow
        nsView.state = .active
    }
}

// Removed CommandBarHeader struct

struct KeyBadge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.custom("Inter", size: 14))
            .fontWeight(.semibold)
            .foregroundColor(Color(hex: "a4a7ae"))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "e9eaeb"), lineWidth: 1)
            )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Clipboard is empty")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ClipboardCard: View {
    let item: ClipboardItem
    let isSelected: Bool
    let showPasteButton: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Header
            HStack(spacing: 12) {
                // Icon Badge
                IconBadge(type: item.type)
                
                // Type Label
                Text(typeLabel)
                    .font(.custom("Inter", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "181d27"))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 64)
            
            // Content Preview
            ContentPreview(item: item)
                .frame(width: 256, height: 192)
        }
        .frame(width: 256, height: 256)
        .background(Color(hex: "f5f5f5"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 1.5, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        .overlay(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 2)
                        .padding(-2)
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "9e77ed"), lineWidth: 4)
                        .padding(-6)
                }
            }
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .overlay(
            Group {
                if showPasteButton {
                    VStack {
                        Spacer()
                        PasteButton()
                            .offset(y: 20)
                    }
                }
            }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    var typeLabel: String {
        switch item.type {
        case .text:
            return "Text"
        case .code:
            return "Code"
        case .url:
            return "URL"
        case .image:
            return "Image"
        }
    }
}

struct IconBadge: View {
    let type: ClipboardItemType
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "fdfdfd"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "d5d7da"), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 0, x: 0, y: -2)
            
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color(hex: "181d27"))
        }
        .frame(width: 40, height: 40)
    }
    
    var iconName: String {
        switch type {
        case .text:
            return "textformat"
        case .code:
            return "chevron.left.forwardslash.chevron.right"
        case .url:
            return "link"
        case .image:
            return "photo"
        }
    }
}

struct ContentPreview: View {
    let item: ClipboardItem
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 20)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.04), radius: 1.5, x: 0, y: 3)
            
            if item.type == .image, let data = item.imageData, let nsImage = NSImage(data: data) {
                let imageSize = nsImage.size
                let isPortrait = imageSize.height > imageSize.width
                
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(
                        maxWidth: isPortrait ? nil : 224,
                        maxHeight: isPortrait ? 160 : nil
                    )
                    .frame(width: 224, height: 160)  // Container frame
                    .clipped()
                    .cornerRadius(8)
            } else if item.type == .code {
                // Code with syntax highlighting
                SyntaxHighlightedText(code: item.content)
                    .font(.custom("Menlo", size: 12))
                    .lineLimit(10)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(16)
            } else {
                // Regular text
                Text(item.content)
                    .font(.custom("Inter", size: 14))
                    .fontWeight(.regular)
                    .foregroundColor(Color(hex: "181d27"))
                    .lineLimit(8)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(16)
            }
        }
    }
}

struct SyntaxHighlightedText: View {
    let code: String
    
    var body: some View {
        Text(highlightedCode())
            .foregroundColor(Color(hex: "181d27"))
    }
    
    func highlightedCode() -> AttributedString {
        var attributed = AttributedString(code)
        
        // Keywords (pink/magenta)
        let keywords = ["import", "export", "const", "let", "var", "function", "class", "func", "def", "public", "private", "static", "async", "await", "return", "if", "else", "for", "while", "switch", "case", "break", "continue", "new", "this", "self", "from", "as", "default"]
        
        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", in: &attributed, color: Color(hex: "dd2590"))
        }
        
        // Strings (blue)
        highlightPattern("\"[^\"]*\"", in: &attributed, color: Color(hex: "1570ef"))
        highlightPattern("'[^']*'", in: &attributed, color: Color(hex: "1570ef"))
        highlightPattern("`[^`]*`", in: &attributed, color: Color(hex: "1570ef"))
        
        // Comments (green)
        highlightPattern("//.*$", in: &attributed, color: Color(hex: "079455"))
        highlightPattern("/\\*.*?\\*/", in: &attributed, color: Color(hex: "079455"))
        highlightPattern("#.*$", in: &attributed, color: Color(hex: "079455"))
        
        return attributed
    }
    
    func highlightPattern(_ pattern: String, in attributedString: inout AttributedString, color: Color) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        
        let nsString = NSString(string: String(attributedString.characters))
        let matches = regex.matches(in: String(attributedString.characters), range: NSRange(location: 0, length: nsString.length))
        
        for match in matches.reversed() {
            if let range = Range(match.range, in: String(attributedString.characters)) {
                if let attrRange = Range(range, in: attributedString) {
                    attributedString[attrRange].foregroundColor = color
                }
            }
        }
    }
}

struct PasteButton: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            Text("Release to Paste")
                .font(.custom("Inter", size: 14))
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "7f56d9"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.12), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 0)
                .shadow(color: Color.black.opacity(0.05), radius: 0, x: 0, y: -2)
        )
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Text {
    func instructionText() -> some View {
        self
            .font(.custom("Inter", size: 14))
            .fontWeight(.semibold)
            .foregroundColor(Color(hex: "717680"))
    }
}
