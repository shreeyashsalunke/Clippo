import SwiftUI

struct OnboardingView: View {
    @ObservedObject var onboardingState: OnboardingState
    let onComplete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color.clear.background(.ultraThinMaterial)
            
            VStack(spacing: 0) {
                // Content based on step
                if onboardingState.currentStep == 0 {
                    WelcomeStep(onNext: { onboardingState.currentStep = 1 })
                } else if onboardingState.currentStep == 1 {
                    AccessibilityStep(onNext: { onboardingState.currentStep = 2 })
                } else {
                    HowToUseStep(onComplete: {
                        onboardingState.isComplete = true
                        onComplete()
                    })
                }
            }
            .frame(width: 512, height: 516)
            .background(Color.themeCardBg(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 20)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 3)
        }
    }
}

// MARK: - Step 1: Welcome
struct WelcomeStep: View {
    let onNext: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // App Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "7F56D9"), Color(hex: "9E77ED")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: "clipboard.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 12)
            
            // Title
            Text("Welcome to PasteHop")
                .font(.custom("Inter", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(Color.themeTextPrimary(for: colorScheme))
            
            // Description
            Text("Your clipboard manager that makes copy-paste a breeze. Access your clipboard history with a simple keyboard shortcut.")
                .font(.custom("Inter", size: 14))
                .fontWeight(.regular)
                .foregroundColor(Color.themeTextSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 48)
            
            Spacer()
            
            // Get Started Button
            OnboardingButton(
                title: "Get Started",
                isPrimary: true,
                action: onNext
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 64)
        }
        .padding(.top, 80)
    }
}

// MARK: - Step 2: Accessibility Permission
struct AccessibilityStep: View {
    let onNext: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var hasPermission = false
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // Accessibility Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "F4EBFF"))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "accessibility")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "7F56D9"))
            }
            .padding(.bottom, 12)
            
            // Title
            Text("Enable Accessibility")
                .font(.custom("Inter", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(Color.themeTextPrimary(for: colorScheme))
            
            // Description
            Text("PasteHop needs accessibility permissions to paste clipboard items automatically. This allows the app to simulate keyboard shortcuts on your behalf.")
                .font(.custom("Inter", size: 14))
                .fontWeight(.regular)
                .foregroundColor(Color.themeTextSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 48)
            
            // Permission Status
            HStack(spacing: 8) {
                Image(systemName: hasPermission ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(hasPermission ? .green : Color(hex: "F79009"))
                
                Text(hasPermission ? "Permission Granted" : "Permission Required")
                    .font(.custom("Inter", size: 12))
                    .fontWeight(.medium)
                    .foregroundColor(Color.themeTextSecondary(for: colorScheme))
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                OnboardingButton(
                    title: "Open System Settings",
                    isPrimary: !hasPermission,
                    action: {
                        openAccessibilitySettings()
                        checkPermission()
                    }
                )
                
                if hasPermission {
                    OnboardingButton(
                        title: "Continue",
                        isPrimary: true,
                        action: onNext
                    )
                } else {
                    Button(action: {
                        checkPermission()
                        if hasPermission {
                            onNext()
                        }
                    }) {
                        Text("Skip for Now")
                            .font(.custom("Inter", size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(Color.themeTextSecondary(for: colorScheme))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 64)
        }
        .padding(.top, 80)
        .onAppear {
            checkPermission()
        }
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

// MARK: - Step 3: How to Use
struct HowToUseStep: View {
    let onComplete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "EFF8FF"))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "0BA5EC"))
            }
            .padding(.bottom, 12)
            
            // Title
            Text("How to Use PasteHop")
                .font(.custom("Inter", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(Color.themeTextPrimary(for: colorScheme))
            
            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                InstructionRow(
                    number: "1",
                    title: "Open PasteHop",
                    description: "Press ⌘ + ⇧ + V to open your clipboard history"
                )
                
                InstructionRow(
                    number: "2",
                    title: "Navigate Items",
                    description: "Keep holding ⌘ + ⇧ and press V to cycle through items"
                )
                
                InstructionRow(
                    number: "3",
                    title: "Paste",
                    description: "Release the keys to paste the selected item"
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Spacer()
            
            // Done Button
            OnboardingButton(
                title: "Done",
                isPrimary: true,
                action: onComplete
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 64)
        }
        .padding(.top, 80)
    }
}

// MARK: - Supporting Views
struct InstructionRow: View {
    let number: String
    let title: String
    let description: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number Badge
            ZStack {
                Circle()
                    .fill(Color(hex: "F9F5FF"))
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.custom("Inter", size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "7F56D9"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Inter", size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themeTextPrimary(for: colorScheme))
                
                Text(description)
                    .font(.custom("Inter", size: 12))
                    .fontWeight(.regular)
                    .foregroundColor(Color.themeTextSecondary(for: colorScheme))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
}

struct OnboardingButton: View {
    let title: String
    let isPrimary: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Inter", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(isPrimary ? .white : Color.themeTextPrimary(for: colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(buttonBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isPrimary ? Color.clear : Color.themeBorder(for: colorScheme), lineWidth: 1)
                )
                .shadow(
                    color: isPrimary ? Color.black.opacity(0.1) : Color.clear,
                    radius: 2,
                    x: 0,
                    y: 1
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    var buttonBackground: some View {
        if isPrimary {
            LinearGradient(
                colors: [Color(hex: "7F56D9"), Color(hex: "9E77ED")],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            Color.clear
        }
    }
}
