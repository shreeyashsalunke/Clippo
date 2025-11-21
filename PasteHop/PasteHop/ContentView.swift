import SwiftUI

struct ContentView: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @Binding var selectionIndex: Int
    
    var body: some View {
        VStack(spacing: 0) {
            if clipboardManager.history.isEmpty {
                Text("Clipboard is empty")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Array(clipboardManager.history.enumerated()), id: \.element.id) { index, item in
                                ClipboardItemView(item: item, isSelected: index == selectionIndex)
                                    .id(index)
                                    .onTapGesture {
                                        selectionIndex = index
                                    }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: selectionIndex) { newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(height: 180)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(16)
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.content)
                .font(.system(size: 12))
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(10)
        .frame(width: 140, height: 120)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .shadow(radius: isSelected ? 4 : 0)
        .animation(.spring(), value: isSelected)
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
