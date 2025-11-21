import SwiftUI

struct ContentView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @Binding var selectionIndex: Int
    
    var body: some View {
        VStack(spacing: 0) {
            if clipboardManager.history.isEmpty {
                EmptyStateView()
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(clipboardManager.history.enumerated()), id: \.element.id) { index, item in
                                ClipboardCard(item: item, isSelected: index == selectionIndex)
                                    .id(index)
                                    .onTapGesture {
                                        selectionIndex = index
                                    }
                            }
                        }
                        .padding(24)
                    }
                    .onChange(of: selectionIndex) { newIndex in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 400, idealWidth: 800, maxWidth: .infinity, minHeight: 240, idealHeight: 280, maxHeight: 320)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 8)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type icon
            HStack(spacing: 8) {
                TypeIcon(type: item.type)
                    .frame(width: 20, height: 20)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                }
            }
            
            // Content Preview
            if item.type == .image, let data = item.imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Text(item.content)
                    .font(.custom("Inter", size: 14))
                    .fontWeight(.medium)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(NSColor.labelColor))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(16)
        .frame(width: 220, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(isSelected ? 1.0 : 0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isSelected ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.05), 
                radius: isSelected ? 12 : 4, 
                x: 0, 
                y: isSelected ? 6 : 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct TypeIcon: View {
    let type: ClipboardItemType
    
    var body: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 32, height: 32)
            
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
        }
    }
    
    var iconName: String {
        switch type {
        case .text:
            return "text.alignleft"
        case .image:
            return "photo"
        }
    }
    
    var iconColor: Color {
        switch type {
        case .text:
            return Color.blue
        case .image:
            return Color.purple
        }
    }
    
    var iconBackgroundColor: Color {
        switch type {
        case .text:
            return Color.blue.opacity(0.15)
        case .image:
            return Color.purple.opacity(0.15)
        }
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
