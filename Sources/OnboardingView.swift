import SwiftUI

// MARK: - Reusable Icon Button Component
struct OnboardingIconButton: View {
    let icon: String
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color(hex: "F5F5F5") : Color.clear)
            
            // Icon
            if let imagePath = Bundle.module.path(forResource: icon, ofType: "png", inDirectory: "Resources"),
               let nsImage = NSImage(contentsOfFile: imagePath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "A4A7AE"))
                    .frame(width: 24, height: 24)
            }
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle()) // Make entire area clickable
        .onTapGesture {
            action()
        }
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Debug Modifier
struct DebugBorder: ViewModifier {
    let color: Color
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        content.overlay(
            isEnabled ? Rectangle().stroke(color, lineWidth: 1) : nil
        )
    }
}

extension View {
    func debugBorder(_ color: Color = .blue, isEnabled: Bool) -> some View {
        modifier(DebugBorder(color: color, isEnabled: isEnabled))
    }
}

struct OnboardingView: View {
    @ObservedObject var onboardingState: OnboardingState
    let onComplete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var showDebugBorders = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Content based on step
                switch onboardingState.currentStep {
                case 0:
                    HelloStep(
                        onNext: { onboardingState.currentStep = 1 },
                        onClose: onComplete,
                        showDebug: showDebugBorders
                    )
                case 1:
                    WalkthroughStep1(
                        onNext: { onboardingState.currentStep = 2 },
                        onBack: { onboardingState.currentStep = 0 },
                        onClose: onComplete,
                        showDebug: showDebugBorders
                    )
                case 2:
                    WalkthroughStep2(
                        onNext: { onboardingState.currentStep = 3 },
                        onBack: { onboardingState.currentStep = 1 },
                        onClose: onComplete,
                        showDebug: showDebugBorders
                    )
                case 3:
                    WalkthroughStep3(
                        onNext: { onboardingState.currentStep = 4 },
                        onBack: { onboardingState.currentStep = 2 },
                        onClose: onComplete,
                        showDebug: showDebugBorders
                    )
                case 4:
                    WalkthroughStep4(
                        onNext: { onboardingState.currentStep = 5 },
                        onBack: { onboardingState.currentStep = 3 },
                        onClose: onComplete,
                        showDebug: showDebugBorders
                    )
                case 5:
                    PermissionStep(
                        onNext: { onboardingState.currentStep = 6 },
                        onBack: { onboardingState.currentStep = 4 },
                        showDebug: showDebugBorders
                    )
                case 6:
                    PermissionGrantedStep(
                        onComplete: {
                            onboardingState.isComplete = true
                            onComplete()
                        },
                        showDebug: showDebugBorders
                    )
                default:
                    HelloStep(
                        onNext: { onboardingState.currentStep = 1 },
                        onClose: onComplete,
                        showDebug: showDebugBorders
                    )
                }
            }
            .frame(width: 424, height: 552)
            .background(Color(hex: "FFFFFF"))
            .cornerRadius(16)
            .debugBorder(.green, isEnabled: showDebugBorders)
            
            // Debug Toggle
            VStack {
                Spacer()
                HStack {
                    Toggle("Debug Layout", isOn: $showDebugBorders)
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        .font(.system(size: 10))
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    Spacer()
                }
                .padding(.leading, -100) // Move it outside the card to the left
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Step 1: Hello
struct HelloStep: View {
    let onNext: () -> Void
    let onClose: () -> Void
    let showDebug: Bool
    
    var body: some View {
        ZStack {
            // Main content card - 552px total height
            VStack(spacing: 0) {
                // Content area - 492px height
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Clippo Illustration
                    if let imagePath = Bundle.module.path(forResource: "clippo-waving-hello", ofType: "png", inDirectory: "Resources"),
                       let clippoImage = NSImage(contentsOfFile: imagePath) {
                        Image(nsImage: clippoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 184, height: 184)
                            .debugBorder(.red, isEnabled: showDebug)
                    } else {
                        // Fallback to system image
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F5F5F5"))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "hand.wave.fill")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(Color(hex: "7F56D9"))
                        }
                        .frame(width: 184, height: 184)
                        .debugBorder(.red, isEnabled: showDebug)
                    }
                    
                    // Spacing between illustration and text
                    Spacer()
                        .frame(height: 24)
                        .debugBorder(.orange, isEnabled: showDebug)
                    
                    // Text Content
                    VStack(spacing: 8) {
                        Text("Hi, I'm Clippo!")
                            .font(.custom("Inter", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "181D27"))
                            .debugBorder(.red, isEnabled: showDebug)
                        
                        VStack(spacing: 0) {
                            Text("I remember what you copy.")
                                .font(.custom("Inter", size: 14))
                                .fontWeight(.regular)
                                .foregroundColor(Color(hex: "535862"))
                                .multilineTextAlignment(.center)
                            
                            Text("Let me give you a 20-second tour.")
                                .font(.custom("Inter", size: 14))
                                .fontWeight(.regular)
                                .foregroundColor(Color(hex: "535862"))
                                .multilineTextAlignment(.center)
                        }
                        .debugBorder(.blue, isEnabled: showDebug)
                    }
                    .debugBorder(.blue, isEnabled: showDebug)
                    
                    Spacer()
                }
                .frame(height: 492) // Content area height
                .frame(maxWidth: .infinity)
                .debugBorder(.purple, isEnabled: showDebug)
                
                // Footer with button
                VStack(spacing: 0) {
                    OnboardingPrimaryButton(
                        title: "Next",
                        action: onNext
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .debugBorder(.green, isEnabled: showDebug)
                }
                .debugBorder(.purple, isEnabled: showDebug)
            }
            .frame(width: 424, height: 552)
            .background(Color(hex: "FFFFFF"))
            .cornerRadius(16)
            
            // Close button floating at top-right
            VStack {
                HStack {
                    Spacer()
                    
                    OnboardingIconButton(
                        icon: "icon-close",
                        action: onClose
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                }
                .padding(.top, 24)
                .padding(.trailing, 24)
                
                Spacer()
            }
            .frame(width: 424, height: 552)
            .debugBorder(.yellow, isEnabled: showDebug)
        }
    }
}

// MARK: - Step 2.1: Walkthrough - Copy Text
struct WalkthroughStep1: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let onClose: () -> Void
    let showDebug: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Content area
                VStack(spacing: 0) {
                    Spacer()
                        .debugBorder(.orange, isEnabled: showDebug)
                    
                    VStack(spacing: 24) {
                        // Illustration
                        Group {
                            if let imagePath = Bundle.module.path(forResource: "walkthrough-illustration", ofType: "png", inDirectory: "Resources"),
                               let illustrationImage = NSImage(contentsOfFile: imagePath) {
                                Image(nsImage: illustrationImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                            } else {
                                // Fallback illustration
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "F5F5F5"))
                                        .frame(height: 160)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 48, weight: .light))
                                            .foregroundColor(Color(hex: "7F56D9"))
                                        
                                        Text("⌘ + C")
                                            .font(.custom("Inter", size: 18))
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(hex: "181D27"))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .debugBorder(.red, isEnabled: showDebug)
                        
                        // Text Content
                        VStack(spacing: 4) {
                            Text("Copy content like usual")
                                .font(.custom("Inter", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "181D27"))
                            
                            Text("Clippo automatically saves everything\nyou copy to your clipboard history.")
                                .font(.custom("Inter", size: 14))
                                .fontWeight(.regular)
                                .foregroundColor(Color(hex: "535862"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 32)
                        }
                        .debugBorder(.blue, isEnabled: showDebug)
                        
                        // Progress dots
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "27727F"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                        }
                        .debugBorder(.blue, isEnabled: showDebug)
                    }
                    .debugBorder(.blue, isEnabled: showDebug)
                    
                    Spacer()
                }
                .frame(height: 492)
                .debugBorder(.purple, isEnabled: showDebug)
                
                // Footer
                VStack(spacing: 0) {
                    OnboardingPrimaryButton(
                        title: "Next",
                        action: onNext
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .debugBorder(.green, isEnabled: showDebug)
                }
                .debugBorder(.purple, isEnabled: showDebug)
            }
            .frame(width: 424, height: 552)
            
            // Floating buttons at top
            VStack {
                HStack {
                    OnboardingIconButton(
                        icon: "icon-back",
                        action: onBack
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                    
                    Spacer()
                    
                    Text("How it works?")
                        .font(.custom("Inter", size: 14))
                        .fontWeight(.regular)
                        .foregroundColor(Color(hex: "535862"))
                    
                    Spacer()
                    
                    OnboardingIconButton(
                        icon: "icon-close",
                        action: onClose
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Spacer()
            }
            .frame(width: 424, height: 552)
            .debugBorder(.yellow, isEnabled: showDebug)
        }
    }
}

// MARK: - Step 2.2: Walkthrough - Open Clippo
struct WalkthroughStep2: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let onClose: () -> Void
    let showDebug: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Content area
                VStack(spacing: 0) {
                    Spacer()
                        .debugBorder(.orange, isEnabled: showDebug)
                    
                    VStack(spacing: 24) {
                        // Illustration
                        Group {
                            if let imagePath = Bundle.module.path(forResource: "walkthrough-open", ofType: "png", inDirectory: "Resources"),
                               let illustrationImage = NSImage(contentsOfFile: imagePath) {
                                Image(nsImage: illustrationImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                            } else {
                                // Fallback illustration
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "F5F5F5"))
                                        .frame(height: 160)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "rectangle.on.rectangle")
                                            .font(.system(size: 48, weight: .light))
                                            .foregroundColor(Color(hex: "7F56D9"))
                                        
                                        HStack(spacing: 4) {
                                            Text("⌘ + ⇧ + V")
                                                .font(.custom("Inter", size: 18))
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color(hex: "181D27"))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .debugBorder(.red, isEnabled: showDebug)
                        
                        // Text Content
                        VStack(spacing: 4) {
                            Text("Open Clippo")
                                .font(.custom("Inter", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "181D27"))
                            
                            Text("Press ⌘⇧V to open your \n clipboard history window.")
                                .font(.custom("Inter", size: 14))
                                .fontWeight(.regular)
                                .foregroundColor(Color(hex: "535862"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 32)
                        }
                        .debugBorder(.blue, isEnabled: showDebug)
                        
                        // Progress dots
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "27727F"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                        }
                        .debugBorder(.blue, isEnabled: showDebug)
                    }
                    .debugBorder(.blue, isEnabled: showDebug)
                    
                    Spacer()
                }
                .frame(height: 492)
                .debugBorder(.purple, isEnabled: showDebug)
                
                // Footer
                VStack(spacing: 0) {
                    OnboardingPrimaryButton(
                        title: "Next",
                        action: onNext
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .debugBorder(.green, isEnabled: showDebug)
                }
                .debugBorder(.purple, isEnabled: showDebug)
            }
            .frame(width: 424, height: 552)
            
            // Floating buttons
            VStack {
                HStack {
                    OnboardingIconButton(
                        icon: "icon-back",
                        action: onBack
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                    
                    Spacer()
                    
                    Text("How it works?")
                        .font(.custom("Inter", size: 14))
                        .fontWeight(.regular)
                        .foregroundColor(Color(hex: "535862"))
                    
                    Spacer()
                    
                    OnboardingIconButton(
                        icon: "icon-close",
                        action: onClose
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Spacer()
            }
            .frame(width: 424, height: 552)
            .debugBorder(.yellow, isEnabled: showDebug)
        }
    }
}

// MARK: - Step 2.3: Walkthrough - Navigate
struct WalkthroughStep3: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let onClose: () -> Void
    let showDebug: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Spacer()
                        .debugBorder(.orange, isEnabled: showDebug)
                    
                    VStack(spacing: 24) {
                        // Illustration
                        Group {
                            if let imagePath = Bundle.module.path(forResource: "walkthrough-navigate", ofType: "png", inDirectory: "Resources"),
                               let illustrationImage = NSImage(contentsOfFile: imagePath) {
                                Image(nsImage: illustrationImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                            } else {
                                // Fallback illustration
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "F5F5F5"))
                                        .frame(height: 160)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "arrow.up.arrow.down")
                                            .font(.system(size: 48, weight: .light))
                                            .foregroundColor(Color(hex: "7F56D9"))
                                        
                                        Text("Keep holding ⌘ + ⇧")
                                            .font(.custom("Inter", size: 16))
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(hex: "181D27"))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .debugBorder(.red, isEnabled: showDebug)
                        
                        // Text Content
                        VStack(spacing: 4) {
                            Text("Navigate items")
                                .font(.custom("Inter", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "181D27"))
                            
                            Text("Keep holding ⌘⇧ and press V repeatedly \n to cycle through your clipboard items.")
                                .font(.custom("Inter", size: 14))
                                .fontWeight(.regular)
                                .foregroundColor(Color(hex: "535862"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 32)
                        }
                        .debugBorder(.blue, isEnabled: showDebug)
                        
                        // Progress dots
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "27727F"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                        }
                        .debugBorder(.blue, isEnabled: showDebug)
                    }
                    .debugBorder(.blue, isEnabled: showDebug)
                    
                    Spacer()
                }
                .frame(height: 492)
                .debugBorder(.purple, isEnabled: showDebug)
                
                // Footer
                VStack(spacing: 0) {
                    OnboardingPrimaryButton(
                        title: "Next",
                        action: onNext
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .debugBorder(.green, isEnabled: showDebug)
                }
                .debugBorder(.purple, isEnabled: showDebug)
            }
            .frame(width: 424, height: 552)
            
            // Floating buttons
            VStack {
                HStack {
                    OnboardingIconButton(
                        icon: "icon-back",
                        action: onBack
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                    
                    Spacer()
                    
                    Text("How it works?")
                        .font(.custom("Inter", size: 14))
                        .fontWeight(.regular)
                        .foregroundColor(Color(hex: "535862"))
                    
                    Spacer()
                    
                    OnboardingIconButton(
                        icon: "icon-close",
                        action: onClose
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Spacer()
            }
            .frame(width: 424, height: 552)
            .debugBorder(.yellow, isEnabled: showDebug)
        }
    }
}

// MARK: - Step 2.4: Walkthrough - Paste
struct WalkthroughStep4: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let onClose: () -> Void
    let showDebug: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Spacer()
                        .debugBorder(.orange, isEnabled: showDebug)
                    
                    VStack(spacing: 24) {
                        // Illustration
                        Group {
                            if let imagePath = Bundle.module.path(forResource: "walkthrough-paste", ofType: "png", inDirectory: "Resources"),
                               let illustrationImage = NSImage(contentsOfFile: imagePath) {
                                Image(nsImage: illustrationImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                            } else {
                                // Fallback illustration
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "F5F5F5"))
                                        .frame(height: 160)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "doc.on.clipboard")
                                            .font(.system(size: 48, weight: .light))
                                            .foregroundColor(Color(hex: "7F56D9"))
                                        
                                        Text("Release keys")
                                            .font(.custom("Inter", size: 16))
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(hex: "181D27"))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .debugBorder(.red, isEnabled: showDebug)
                        
                        // Text Content
                        VStack(spacing: 4) {
                            Text("Release keys to paste")
                                .font(.custom("Inter", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "181D27"))
                            
                            Text("Release the keys to automatically paste \n the selected clipboard item.")
                                .font(.custom("Inter", size: 14))
                                .fontWeight(.regular)
                                .foregroundColor(Color(hex: "535862"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 32)
                        }
                        .debugBorder(.blue, isEnabled: showDebug)
                        
                        // Progress dots
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "D5D7DA"))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color(hex: "27727F"))
                                .frame(width: 8, height: 8)
                        }
                        .debugBorder(.blue, isEnabled: showDebug)
                    }
                    .debugBorder(.blue, isEnabled: showDebug)
                    
                    Spacer()
                }
                .frame(height: 492)
                .debugBorder(.purple, isEnabled: showDebug)
                
                // Footer
                VStack(spacing: 0) {
                    OnboardingPrimaryButton(
                        title: "Next",
                        action: onNext
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .debugBorder(.green, isEnabled: showDebug)
                }
                .debugBorder(.purple, isEnabled: showDebug)
            }
            .frame(width: 424, height: 552)
            
            // Floating buttons
            VStack {
                HStack {
                    OnboardingIconButton(
                        icon: "icon-back",
                        action: onBack
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                    
                    Spacer()
                    
                    Text("How it works?")
                        .font(.custom("Inter", size: 14))
                        .fontWeight(.regular)
                        .foregroundColor(Color(hex: "535862"))
                    
                    Spacer()
                    
                    OnboardingIconButton(
                        icon: "icon-close",
                        action: onClose
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Spacer()
            }
            .frame(width: 424, height: 552)
            .debugBorder(.yellow, isEnabled: showDebug)
        }
    }
}

// MARK: - Step 3: Permission Request
struct PermissionStep: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let showDebug: Bool
    @State private var hasPermission = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "F4EBFF"))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "lock.shield")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color(hex: "7F56D9"))
            }
            .debugBorder(.red, isEnabled: showDebug)
            
            // Text Content
            VStack(spacing: 8) {
                Text("Enable Accessibility")
                    .font(.custom("Inter", size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "181D27"))
                
                Text("Clippo needs accessibility permission to paste items automatically. This allows the app to simulate keyboard shortcuts.")
                    .font(.custom("Inter", size: 14))
                    .fontWeight(.regular)
                    .foregroundColor(Color(hex: "535862"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .debugBorder(.blue, isEnabled: showDebug)
            
            // Permission Status
            if hasPermission {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "12B76A"))
                    
                    Text("Permission granted")
                        .font(.custom("Inter", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "027A48"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "ECFDF3"))
                .cornerRadius(8)
                .debugBorder(.green, isEnabled: showDebug)
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                if hasPermission {
                    OnboardingPrimaryButton(
                        title: "Continue",
                        action: onNext
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                } else {
                    OnboardingPrimaryButton(
                        title: "Open System Settings",
                        action: {
                            openAccessibilitySettings()
                            checkPermission()
                        }
                    )
                    .debugBorder(.green, isEnabled: showDebug)
                    
                    Button(action: onNext) {
                        Text("Skip for now")
                            .font(.custom("Inter", size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "535862"))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .debugBorder(.green, isEnabled: showDebug)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .debugBorder(.purple, isEnabled: showDebug)
        }
        .padding(.top, 80)
        .onAppear {
            checkPermission()
        }
        .debugBorder(.yellow, isEnabled: showDebug)
    }
    
    func checkPermission() {
        hasPermission = AXIsProcessTrusted()
    }
    
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        
        // Check permission after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkPermission()
        }
    }
}

// MARK: - Step 3.1: Permission Granted
struct PermissionGrantedStep: View {
    let onComplete: () -> Void
    let showDebug: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "ECFDF3"))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(Color(hex: "12B76A"))
            }
            .debugBorder(.red, isEnabled: showDebug)
            
            // Text Content
            VStack(spacing: 8) {
                Text("You're all set!")
                    .font(.custom("Inter", size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "181D27"))
                
                Text("Clippo is ready to help you manage your clipboard. Press ⌘ + ⇧ + V anytime to get started.")
                    .font(.custom("Inter", size: 14))
                    .fontWeight(.regular)
                    .foregroundColor(Color(hex: "535862"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .debugBorder(.blue, isEnabled: showDebug)
            
            Spacer()
            
            // Done Button
            OnboardingPrimaryButton(
                title: "Get Started",
                action: onComplete
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .debugBorder(.green, isEnabled: showDebug)
        }
        .padding(.top, 80)
        .debugBorder(.yellow, isEnabled: showDebug)
    }
}

// MARK: - Button Components
struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Inter", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isHovering ? Color(hex: "1F5C66") : Color(hex: "27727F"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 2)
                )
                .shadow(color: Color(hex: "0A0D12").opacity(0.05), radius: 1, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "0A0D12").opacity(0.18), lineWidth: 1)
                        .padding(1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(hex: "0A0D12").opacity(0.05), location: 0),
                                    .init(color: Color.clear, location: 0.5)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: 2)
                        .offset(y: 21)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

struct OnboardingSecondaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Inter", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "181D27"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(hex: "FFFFFF"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "D5D7DA"), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}


