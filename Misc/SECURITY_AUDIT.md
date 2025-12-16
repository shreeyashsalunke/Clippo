# Security & Privacy Audit Report for Clippo

## Executive Summary
Clippo is a clipboard manager that handles potentially sensitive data. This audit identifies security and privacy concerns and provides fixes.

## ✅ POSITIVE FINDINGS (Good Security Practices)

1. **No Network Calls** - No URLSession usage found. Data stays local. ✓
2. **In-Memory Storage** - Clipboard history is stored only in RAM (@Published var history), not persisted to disk. ✓
3. **Limited History** - Only keeps 5 items maximum, reducing exposure window. ✓
4. **Password Detection** - Has password manager detection and content analysis. ✓
5. **No Third-Party Dependencies** - Pure Swift with no external packages. ✓
6. **Accessibility Permission Required** - Properly gates auto-paste feature. ✓

## 🔴 CRITICAL SECURITY ISSUES

### 1. **Bundle Identifier is Placeholder**
**Risk**: High - App Store rejection, signing issues, could conflict with other apps
**Location**: `build_app.sh` line 72
**Current**: `com.yourname.Clippo`
**Fix Required**: Use proper reverse DNS notation

### 2. **File Path Disclosure**
**Risk**: Medium - Full file paths are stored and displayed
**Location**: `ClipboardManager.swift` - fileURLs stored with full paths
**Issue**: Exposes user directory structure
**Recommendation**: Display only lastPathComponent, store full path only when needed

### 3. **Source App Bundle ID Exposure**
**Risk**: Low-Medium - Stores which app data was copied from
**Location**: `ClipboardManager.swift` line 99
**Privacy Concern**: Tracks user behavior across apps
**Current**: `NSWorkspace.shared.frontmostApplication?.bundleIdentifier`

## ⚠️ PRIVACY CONCERNS

### 4. **UserDefaults Storage**
**Risk**: Low - Settings stored in plain text
**Data Stored**:
- `passwordProtectionEnabled` (boolean)
- `onboardingComplete` (boolean)
- `appIsDarkMode` (boolean)
- `hotkey_keyCode`, `hotkey_modifiers`, `hotkey_customized`

**Recommendation**: This is acceptable for app settings, but document this in Privacy Policy

### 5. **Clipboard Data in Memory**
**Risk**: Medium - Sensitive data remains in memory until app quits or history cleared
**Issue**: 
- Images, text, files remain accessible
- No auto-clear on app background/quit
- No encryption at rest (even in RAM)

### 6. **File Access Without User Consent**
**Risk**: Low - FileManager checks file types without explicit per-file permission
**Location**: `ClipboardManager.swift` lines 49, 60
**Issue**: Checks if path is directory without sandboxing restrictions

## 🛡️ MISSING SECURITY FEATURES

### 7. **No Privacy Policy Declaration**
**Required**: Info.plist should declare clipboard usage purpose
**Missing**: NSAppleEventsUsageDescription, NSAccessibilityUsageDescription with clear explanations

### 8. **No Data Sanitization for Display**
**Risk**: Low - Long text/filenames could cause UI issues or crashes
**Recommendation**: Truncate display text, validate UTF-8

### 9. **No Code Signing Properties**
**Risk**: High for distribution
**Missing**: Entitlements file, codesigning in build script

### 10. **No Sandboxing**
**Risk**: Medium - App has full system access
**Recommendation**: Enable App Sandbox with proper entitlements for App Store

## 📋 RECOMMENDATIONS

### Immediate Fixes (Critical):
1. Update bundle identifier
2. Add privacy usage descriptions to Info.plist
3. Add code signing to build process

### Short-term (Important):
4. Add auto-clear history on quit option
5. Sanitize display text
6. Add Privacy Policy
7. Consider encryption for sensitive clipboard items

### Long-term (Enhanced Security):
8. Implement App Sandbox
9. Add option to exclude certain apps from clipboard capture
10. Add local authentication (Touch ID/Password) to view history
11. Add secure enclave storage for sensitive items

## 🔧 RECOMMENDED FIXES

See separate files for code changes.
