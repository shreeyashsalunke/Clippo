import SwiftUI
import Combine

class OnboardingState: ObservableObject {
    @Published var currentStep: Int = 0
    
    private var _isComplete: Bool = false
    var isComplete: Bool {
        get { _isComplete }
        set {
            _isComplete = newValue
            if newValue {
                UserDefaults.standard.set(true, forKey: "onboardingComplete")
            }
            // Do not trigger view update here to prevent crash on dismissal
        }
    }
    
    init() {
        self._isComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    }
    
    func reset() {
        currentStep = 0
        _isComplete = false
        UserDefaults.standard.set(false, forKey: "onboardingComplete")
        objectWillChange.send()
    }
}
