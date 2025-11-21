import SwiftUI

struct ContentView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @Binding var selectionIndex: Int
    @Binding var isPasting: Bool
    @Environment(\.colorScheme) var colorScheme
    
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
                            showPasteButton: index == selectionIndex,
                            isPasting: isPasting && index == selectionIndex
                        )
                        .onTapGesture {
                            selectionIndex = index
                        }
                    }
                }
            }
            
            // Footer: Keyboard Instructions
            if clipboardManager.history.count > 1 {
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
                .padding(.top, 16)
            }
        }
        .padding(.horizontal, 64)
        .padding(.vertical, 48)
        .frame(width: calculateWidth(), height: 420)
        .background(
            ZStack {
                // Backdrop blur
                Color.clear.background(.ultraThinMaterial)
                
                // Semi-transparent white overlay
                Color.themeOverlayTint(for: colorScheme)
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



// Removed CommandBarHeader struct

struct KeyBadge: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text(text)
            .font(.custom("Inter", size: 14))
            .fontWeight(.semibold)
            .foregroundColor(.themeTextSecondary(for: colorScheme))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.themeKeyBg(for: colorScheme))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.themeBorder(for: colorScheme), lineWidth: 1)
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
    let isPasting: Bool
    @Environment(\.colorScheme) var colorScheme
    
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
                    .foregroundColor(Color.themeTextPrimary(for: colorScheme))
                
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
        .background(Color.themeCardBg(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 1.5, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        .overlay(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.themeKeyBg(for: colorScheme), lineWidth: 2)
                        .padding(-2)
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isPasting ? Color.green : .themeSelectionRing(for: colorScheme), lineWidth: 4)
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
                        PasteButton(isPasting: isPasting)
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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.themeIconBg(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.themeIconBorder(for: colorScheme), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 0, x: 0, y: -2)
            
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color.themeTextPrimary(for: colorScheme))
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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeKeyBg(for: colorScheme))
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
                    .foregroundColor(Color.themeTextPrimary(for: colorScheme))
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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text(highlightedCode())
            .foregroundColor(Color.themeTextPrimary(for: colorScheme))
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
    var isPasting: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isPasting ? "checkmark" : "doc.on.clipboard")
                .font(.system(size: 14, weight: .semibold))
            Text(isPasting ? "Pasted!" : "Release to Paste")
                .font(.custom("Inter", size: 14))
                .fontWeight(.semibold)
                .padding(.trailing, isPasting ? 8 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isPasting ? Color.green : .themeAccent(for: colorScheme))
        .foregroundColor(.white)
        .cornerRadius(8)
        .shadow(color: Color.themeAccent(for: colorScheme).opacity(0.24), radius: 8, x: 0, y: 4)
        .scaleEffect(isPasting ? 1.1 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPasting)
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
        InstructionTextModifier(text: self)
    }
}

struct InstructionTextModifier: View {
    let text: Text
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        text
            .font(.custom("Inter", size: 14))
            .fontWeight(.semibold)
            .foregroundColor(.themeTextSecondary(for: colorScheme))
    }
}

extension NSColor {
    convenience init(hex: String) {
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
            srgbRed: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
    
    static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}

extension Color {
    static func themeTextPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "F9FAFB") : Color(hex: "181d27")
    }
    
    static func themeTextSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "98A2B3") : Color(hex: "475467")
    }
    
    static func themeCardBg(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "161b26") : Color(hex: "f5f5f5")
    }
    
    static func themeBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "344054") : Color(hex: "e9eaeb")
    }
    
    static func themeAccent(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "9E77ED") : Color(hex: "7f56d9")
    }
    
    static func themeIconBg(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "101828") : Color(hex: "fdfdfd")
    }
    
    static func themeIconBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "344054") : Color(hex: "d5d7da")
    }
    
    static func themeKeyBg(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1D2939") : .white
    }
    
    static func themeOverlayTint(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.2)
    }
    
    static func themeSelectionRing(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "B692F6") : Color(hex: "9e77ed")
    }
}
