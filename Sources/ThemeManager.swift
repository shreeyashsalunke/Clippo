import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "appIsDarkMode")
        }
    }
    
    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
    
    private init() {
        // Load from UserDefaults
        self.isDarkMode = UserDefaults.standard.bool(forKey: "appIsDarkMode")
    }
    
    func toggle() {
        isDarkMode.toggle()
    }
}
