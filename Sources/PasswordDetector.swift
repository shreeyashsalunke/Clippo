import Foundation
import AppKit

class PasswordDetector {
    // Known password manager bundle IDs
    static let passwordManagerBundleIDs: Set<String> = [
        "com.agilebits.onepassword7",           // 1Password 7
        "com.agilebits.onepassword-osx",        // 1Password 8
        "com.bitwarden.desktop",                // Bitwarden
        "com.lastpass.LastPass",                // LastPass
        "com.dashlane.dashlanephonefinal",      // Dashlane
        "com.outercorner.secrets",              // Secrets
        "in.sinew.Enpass-Desktop",              // Enpass
        "com.apple.keychainaccess",             // Keychain Access
        "org.keepassx.keepassxc",               // KeePassXC
        "com.meldium.Meldium"                   // Meldium
    ]
    
    /// Check if clipboard content should be ignored based on frontmost app
    static func shouldIgnoreFromApp(_ bundleID: String?) -> Bool {
        guard let bundleID = bundleID else { return false }
        return passwordManagerBundleIDs.contains(bundleID)
    }
    
    /// Get the bundle ID of the frontmost application
    static func getFrontmostAppBundleID() -> String? {
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
    
    /// Analyze text content to determine if it looks like a password or secret
    static func isLikelySecret(_ text: String) -> Bool {
        // Skip empty or very short strings
        guard text.count >= 8 && text.count <= 128 else { return false }
        
        // Skip if it looks like a URL
        if isURL(text) { return false }
        
        // Skip if it looks like a hex color
        if isHexColor(text) { return false }
        
        // Skip if it looks like code
        if isCodePattern(text) { return false }
        
        // Skip if it looks like a phone number
        if isPhoneNumber(text) { return false }
        
        // Skip if it has too many spaces (likely normal text)
        let spaceCount = text.filter { $0.isWhitespace }.count
        if spaceCount > 2 { return false }
        
        // Check for password characteristics
        let hasUppercase = text.contains(where: { $0.isUppercase })
        let hasLowercase = text.contains(where: { $0.isLowercase })
        let hasDigit = text.contains(where: { $0.isNumber })
        let hasSymbol = text.contains(where: { !$0.isLetter && !$0.isNumber && !$0.isWhitespace })
        
        // Count how many character types are present
        let characterTypeCount = [hasUppercase, hasLowercase, hasDigit, hasSymbol].filter { $0 }.count
        
        // Likely a password if it has at least 3 different character types
        if characterTypeCount >= 3 {
            // Check character diversity (not all repeating)
            if hasGoodCharacterDiversity(text) {
                return true
            }
        }
        
        // Check for common secret patterns (API keys, tokens)
        if looksLikeAPIKey(text) {
            return true
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    
    private static func isURL(_ text: String) -> Bool {
        // Check for common URL patterns
        let urlPrefixes = ["http://", "https://", "ftp://", "www."]
        for prefix in urlPrefixes {
            if text.lowercased().hasPrefix(prefix) {
                return true
            }
        }
        
        // Check if it contains domain-like pattern
        if text.contains(".com") || text.contains(".org") || text.contains(".net") {
            return true
        }
        
        return false
    }
    
    private static func isHexColor(_ text: String) -> Bool {
        // Check for hex color patterns like #FFFFFF or 0xFFFFFF
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("#") && trimmed.count == 7 {
            let hex = String(trimmed.dropFirst())
            return hex.allSatisfy { $0.isHexDigit }
        }
        if trimmed.hasPrefix("0x") && trimmed.count == 8 {
            let hex = String(trimmed.dropFirst(2))
            return hex.allSatisfy { $0.isHexDigit }
        }
        return false
    }
    
    private static func isCodePattern(_ text: String) -> Bool {
        // Check for common code keywords
        let codeKeywords = [
            "function", "import", "export", "const", "let", "var",
            "class", "def", "return", "if", "else", "for", "while",
            "public", "private", "static", "void", "int", "string"
        ]
        
        let lowercased = text.lowercased()
        for keyword in codeKeywords {
            if lowercased.contains(keyword) {
                return true
            }
        }
        
        // Check for common code patterns
        if text.contains("()") || text.contains("{}") || text.contains("[]") {
            return true
        }
        
        return false
    }
    
    private static func isPhoneNumber(_ text: String) -> Bool {
        // Remove common phone number separators
        let cleaned = text.replacingOccurrences(of: "[\\s\\-\\(\\)\\.]", with: "", options: .regularExpression)
        
        // Check if it's mostly digits with optional + at start
        let digitsOnly = cleaned.hasPrefix("+") ? String(cleaned.dropFirst()) : cleaned
        
        if digitsOnly.count >= 10 && digitsOnly.count <= 15 {
            return digitsOnly.allSatisfy { $0.isNumber }
        }
        
        return false
    }
    
    private static func hasGoodCharacterDiversity(_ text: String) -> Bool {
        // Check that it's not all repeating characters
        let uniqueChars = Set(text)
        let diversityRatio = Double(uniqueChars.count) / Double(text.count)
        
        // At least 40% unique characters
        return diversityRatio >= 0.4
    }
    
    private static func looksLikeAPIKey(_ text: String) -> Bool {
        // Common API key patterns
        let apiKeyPrefixes = [
            "sk_", "pk_", "api_", "key_", "token_",
            "AIza", "AKIA", "ya29.", "ghp_", "gho_"
        ]
        
        for prefix in apiKeyPrefixes {
            if text.hasPrefix(prefix) {
                return true
            }
        }
        
        // Check for base64-like patterns (long alphanumeric with +/=)
        if text.count > 20 {
            let base64Chars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
            let textCharSet = CharacterSet(charactersIn: text)
            if textCharSet.isSubset(of: base64Chars) {
                return true
            }
        }
        
        return false
    }
}
