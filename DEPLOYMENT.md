# Clippo Deployment Guide

## 1. Building the App Locally
To build `Clippo.app` for local testing and distribution:

1. Open Terminal in the project folder.
2. Run the build script:
   ```bash
   ./build_app.sh
   ```
3. This will create **Clippo.app** in the current directory.
4. You can drag this app to your Applications folder.

The script automatically:
- Compiles the Swift code in release mode.
- Generates a proper `AppIcon.icns` from your logo file.
- Bundles everything into a macOS Application Bundle.

## 2. Publishing to the Mac App Store

To publish to the Mac App Store, you need to use Xcode to handle signing, sandboxing, and archiving.

### Step 1: Open in Xcode
1. Open Xcode.
2. Select **File > Open...** and choose the `Clippo` folder (the folder containing `Package.swift`).
3. Xcode will open the project as a Swift Package.

### Step 2: Configure App Icon
1. In the Project Navigator (left sidebar), right-click on `Sources/Resources` and select **New File...**.
2. Scroll down to **Resource** and select **Asset Catalog**. Name it `Media.xcassets`.
3. Open `Media.xcassets`.
4. Right-click in the empty list area and select **App Icons & Launch Images > New macOS App Icon**.
5. Drag your logo image (`Sources/Resources/clippo-logo.icon/Assets/Frame 98.png`) into the **1024pt** slot (and others if you resize them).

### Step 3: Configure Signing & Capabilities
1. Click on the **Clippo** project icon in the top left of the Project Navigator.
2. Select the **Clippo** target.
3. Go to the **Signing & Capabilities** tab.
4. **Team**: Select your Apple Developer Account.
5. **Bundle Identifier**: Change `com.yourname.Clippo` to your unique identifier (e.g., `com.shreeyashs.Clippo`).
6. **App Sandbox**: Click **+ Capability** and add **App Sandbox**.
   - **Important**: For a clipboard manager, you might need specific entitlements.
   - Under **App Sandbox**, check **Hardware > Printing** (if needed) or **File Access** if you save files.
   - *Note*: The "Accessibility Permission" (`AXIsProcessTrusted`) relies on the user granting permission in System Settings. This works in a sandboxed app, but you must ensure your app is properly signed.

### Step 4: Archive and Submit
1. Select **Product > Archive** from the menu bar.
2. Once the archive is created, the Organizer window will open.
3. Click **Distribute App**.
4. Select **App Store Connect** and follow the prompts to upload your build.

## Troubleshooting
- **Accessibility Permission**: If the permission prompt doesn't appear in the sandboxed build, ensure your `Info.plist` (managed by Xcode) includes `NSAppleEventsUsageDescription` if you are scripting other apps (though `CGEvent` usually doesn't require it).
- **Status Bar Icon**: If the status bar icon looks too big or doesn't adapt to dark mode, ensure you use a template image (PDF or PNG with "Render as Template" set in Asset Catalog).
