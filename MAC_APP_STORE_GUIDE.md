# Complete Mac App Store Submission Guide for Clippo

## Prerequisites

Before you begin, ensure you have:

1. **Apple Developer Account** ($99/year)
   - Sign up at: https://developer.apple.com/programs/
   
2. **Xcode** (Latest version)
   - Download from Mac App Store
   
3. **App Store Connect Access**
   - Visit: https://appstoreconnect.apple.com/

---

## Part 1: Prepare Your Xcode Project

Since you're using Swift Package Manager, you'll need to create an Xcode project.

### Option A: Create Xcode Project (Recommended for App Store)

1. **Open Xcode**
2. **File > New > Project**
3. Choose **macOS > App**
4. Fill in:
   - **Product Name**: Clippo
   - **Team**: Select your Apple Developer team
   - **Organization Identifier**: `com.shreeyashs` (or your domain)
   - **Bundle Identifier**: `com.shreeyashs.Clippo`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Uncheck** "Use Core Data"
   - **Uncheck** "Include Tests"
5. Save to a new folder (e.g., `ClippoXcode`)

### Copy Your Code to the New Project

1. Delete the default `ContentView.swift` and `ClippoApp.swift` that Xcode created
2. In Finder, drag all `.swift` files from your `Sources` folder into the Xcode project
3. Copy the `Resources` folder into the project
4. Make sure files are added to the target

---

## Part 2: Configure App Icon

### Create App Icon Asset

1. In Xcode, select **Assets.xcassets** (in the left sidebar)
2. Click on **AppIcon**
3. You need to provide different sizes. Use your logo at:
   - `Sources/Resources/clippo-logo.icon/Assets/Frame 98.png`

#### Generate All Required Sizes

Open Terminal and run this script to generate all icon sizes:

```bash
cd ~/Desktop
SOURCE="/Users/shreeyashs/Dev/Clippo/Sources/Resources/clippo-logo.icon/Assets/Frame 98.png"
ICONSET="Clippo.iconset"
mkdir -p "$ICONSET"

sips -z 16 16     "$SOURCE" --out "$ICONSET/icon_16x16.png"
sips -z 32 32     "$SOURCE" --out "$ICONSET/icon_16x16@2x.png"
sips -z 32 32     "$SOURCE" --out "$ICONSET/icon_32x32.png"
sips -z 64 64     "$SOURCE" --out "$ICONSET/icon_32x32@2x.png"
sips -z 128 128   "$SOURCE" --out "$ICONSET/icon_128x128.png"
sips -z 256 256   "$SOURCE" --out "$ICONSET/icon_128x128@2x.png"
sips -z 256 256   "$SOURCE" --out "$ICONSET/icon_256x256.png"
sips -z 512 512   "$SOURCE" --out "$ICONSET/icon_256x256@2x.png"
sips -z 512 512   "$SOURCE" --out "$ICONSET/icon_512x512.png"
sips -z 1024 1024 "$SOURCE" --out "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET"
echo "Icon created at ~/Desktop/Clippo.icns"
```

4. Drag the generated `Clippo.icns` file into the **AppIcon** section in Assets.xcassets

---

## Part 3: Configure Signing & Capabilities

### 1. Signing

1. Click on your project name in the left sidebar (top of the file tree)
2. Select the **Clippo** target
3. Go to **Signing & Capabilities** tab
4. **Automatically manage signing**: ✅ Check this
5. **Team**: Select your Apple Developer team
6. **Bundle Identifier**: Ensure it's `com.shreeyashs.Clippo`

### 2. Required Capabilities

#### Add App Sandbox
1. Click **+ Capability**
2. Search for **App Sandbox**
3. Add it
4. Configure:
   - ✅ **Incoming Connections (Server)**
   - ✅ **Outgoing Connections (Client)**
   - Under **File Access**: None (unless you need it)
   - Under **Hardware**: None

#### Add Hardened Runtime (Automatic with modern Xcode)
This is usually added automatically when you enable signing.

### 3. Update Info.plist

1. Select `Info.plist` in the project navigator
2. Add these keys:

| Key | Type | Value |
|-----|------|-------|
| `NSAppleEventsUsageDescription` | String | "Clippo needs access to paste clipboard content into other applications." |
| `NSAccessibilityUsageDescription` | String | "Clippo needs accessibility access to paste clipboard items on your behalf." |
| `LSUIElement` | Boolean | YES |
| `CFBundleDisplayName` | String | Clippo |
| `CFBundleShortVersionString` | String | 1.0 |
| `CFBundleVersion` | String | 1 |

---

## Part 4: App Store Connect Setup

### 1. Create App Record

1. Go to https://appstoreconnect.apple.com/
2. Click **My Apps**
3. Click **+** button (top left)
4. Select **New App**
5. Fill in:
   - **Platform**: macOS
   - **Name**: Clippo
   - **Primary Language**: English
   - **Bundle ID**: Select `com.shreeyashs.Clippo`
   - **SKU**: `clippo-1` (unique identifier for your records)
   - **User Access**: Full Access

### 2. Prepare App Information

You'll need to provide:

#### Screenshots
- At least 3 screenshots showing the app in action
- Recommended sizes: 1280x800 or 2880x1800
- Show key features: clipboard history, dark/light mode, onboarding

#### App Description
```
Clippo is a powerful clipboard manager for macOS that remembers everything you copy.

KEY FEATURES:
• Quick Access - Press ⌘⇧V to instantly view your clipboard history
• Smart Navigation - Cycle through items with keyboard shortcuts
• Auto Paste - Release keys to paste selected items
• Password Protection - Automatically ignores sensitive content
• Beautiful Design - Native macOS design with dark mode support
• Privacy First - All data stored locally on your Mac

Perfect for developers, writers, and anyone who copies and pastes frequently.
```

#### Keywords
`clipboard, manager, copy, paste, productivity, utility, snippets`

#### Categories
- **Primary**: Utilities
- **Secondary**: Productivity

#### App Privacy
You'll need to answer questions about data collection. For Clippo:
- **Collects Data**: No
- **Tracks Users**: No

---

## Part 5: Build and Archive

### 1. Clean Build

1. In Xcode: **Product > Clean Build Folder** (⇧⌘K)

### 2. Select "Any Mac"

1. At the top of Xcode, click the device selector (next to Play/Stop buttons)
2. Select **Any Mac (Apple Silicon, Intel)**

### 3. Archive

1. **Product > Archive**
2. Wait for the build to complete (5-10 minutes)
3. The **Organizer** window will open automatically

### 4. Validate Archive

1. In Organizer, select your archive
2. Click **Validate App**
3. Follow the prompts
4. Fix any errors that appear

Common issues:
- **Missing entitlements**: Add required capabilities
- **Signing issues**: Ensure correct team is selected
- **API usage**: May need to declare certain APIs in use

### 5. Distribute to App Store

1. Click **Distribute App**
2. Select **App Store Connect**
3. Click **Upload**
4. Select signing options:
   - ✅ **Automatically manage signing**
5. Click **Upload**
6. Wait for processing (10-30 minutes)

---

## Part 6: Submit for Review

### 1. Complete App Store Listing

1. Go back to App Store Connect
2. Find your app
3. Complete all required fields:
   - [ ] Screenshots
   - [ ] Description
   - [ ] Keywords
   - [ ] Support URL (your website or GitHub)
   - [ ] Marketing URL (optional)
   - [ ] Version information
   - [ ] Copyright

### 2. Set Pricing

1. Click **Pricing and Availability**
2. Choose:
   - **Free** or set a price
   - Select countries/regions
   - Set availability date

### 3. Add Build

1. In the **App Store** tab
2. Under **Build**, click **+ Select a build to submit**
3. Choose your uploaded build
4. Answer export compliance questions:
   - Does your app use encryption? **No** (unless you added custom encryption)

### 4. Submit for Review

1. Click **Add for Review** (top right)
2. Click **Submit to App Review**
3. Confirm submission

### 5. Review Process

- **Review time**: Typically 24-48 hours
- You'll receive emails about status changes
- The app can be:
  - ✅ **Approved**: Goes live immediately (or on scheduled date)
  - ⚠️ **Metadata Rejected**: Fix description/screenshots
  - ❌ **Rejected**: Fix code issues and resubmit

---

## Part 7: Common Rejection Reasons & Solutions

### 1. Accessibility Permission Not Clear
**Problem**: Reviewers don't know why accessibility is needed

**Solution**: 
- Add clear `NSAccessibilityUsageDescription` text
- Show permission request in onboarding screenshots

### 2. Minimal Functionality
**Problem**: App seems too simple

**Solution**: 
- Emphasize unique features in description
- Show advanced use cases in screenshots

### 3. Sandbox Violations
**Problem**: App tries to do things not allowed in sandbox

**Solution**:
- Ensure you're only accessing clipboard
- Don't try to access files outside sandbox without permission

### 4. Missing Menu Bar
**Problem**: App has no visible UI

**Solution**:
- Your status bar menu counts as UI
- Make sure it's clearly shown in screenshots

---

## Quick Checklist

- [ ] Created Xcode project with proper Bundle ID
- [ ] Added all source files and resources
- [ ] Configured App Icon in Assets.xcassets
- [ ] Enabled App Sandbox capability
- [ ] Added usage descriptions to Info.plist
- [ ] Created App Store Connect record
- [ ] Uploaded at least 3 screenshots
- [ ] Written compelling app description
- [ ] Successfully archived the app
- [ ] Validated the archive
- [ ] Uploaded to App Store Connect
- [ ] Completed all app information
- [ ] Submitted for review

---

## Support Resources

- **App Review Process**: https://developer.apple.com/app-store/review/
- **App Store Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Sandbox Guide**: https://developer.apple.com/documentation/security/app_sandbox
- **App Store Connect Help**: https://help.apple.com/app-store-connect/

---

## Tips for Success

1. **Test Thoroughly**: Test on both Intel and Apple Silicon Macs
2. **Clear Documentation**: Include clear onboarding for first-time users
3. **Privacy Policy**: Even if you collect no data, having a privacy policy page helps
4. **Support Channel**: Set up an email or website for user support
5. **Version Numbers**: Follow semantic versioning (1.0.0, 1.1.0, etc.)

Good luck with your submission! 🚀
