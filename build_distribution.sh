#!/bin/bash

# Exit on error
set -e

APP_NAME="Clippo"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
DIST_DIR="dist"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"

echo "🚀 Building $APP_NAME for distribution..."

# 1. Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 2. Build the app (release mode)
echo "🛠️  Building app in release mode..."
./build_app.sh

# 3. Verify the app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: $APP_BUNDLE not found!"
    exit 1
fi

echo "✅ App bundle created successfully"

# 4. Create ZIP archive (simpler for distribution)
echo "📦 Creating ZIP archive..."
cd "$APP_BUNDLE/.."
zip -r "$ZIP_NAME" "$APP_NAME.app" -x "*.DS_Store"
mv "$ZIP_NAME" "$DIST_DIR/"
cd - > /dev/null

echo "✅ ZIP created: $DIST_DIR/$ZIP_NAME"

# 5. Create DMG (macOS standard for distribution)
echo "💿 Creating DMG image..."

# Create temporary directory for DMG
TMP_DMG_DIR="/tmp/${APP_NAME}_dmg"
rm -rf "$TMP_DMG_DIR"
mkdir -p "$TMP_DMG_DIR"

# Copy app to temp directory
cp -R "$APP_BUNDLE" "$TMP_DMG_DIR/"

# Create README
cat > "$TMP_DMG_DIR/README.txt" << 'EOF'
Clippo - Clipboard Manager for macOS

INSTALLATION:
1. Drag Clippo.app to your Applications folder
2. Open Clippo from Applications
3. Follow the onboarding to grant permissions

FIRST TIME SETUP:
- Grant Accessibility permission when prompted
- This allows Clippo to auto-paste clipboard items
- You can change the hotkey in Settings (default: ⌘⇧V)

PRIVACY:
- All data stays on your Mac
- Nothing is sent to external servers
- History is cleared when you quit the app

SUPPORT:
For issues or questions, visit: https://github.com/yourusername/clippo

VERSION: 1.0.0
EOF

# Create Applications symlink for easy drag-and-drop
ln -s /Applications "$TMP_DMG_DIR/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TMP_DMG_DIR" \
    -ov -format UDZO \
    "$DIST_DIR/$DMG_NAME"

# Cleanup
rm -rf "$TMP_DMG_DIR"

echo "✅ DMG created: $DIST_DIR/$DMG_NAME"

# 6. Generate checksums
echo "🔐 Generating checksums..."
cd "$DIST_DIR"
shasum -a 256 "$ZIP_NAME" > "${ZIP_NAME}.sha256"
shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
cd - > /dev/null

echo "✅ Checksums generated"

# 7. Create distribution info
cat > "$DIST_DIR/DISTRIBUTION_INFO.txt" << EOF
Clippo v${VERSION} - Distribution Package
=========================================

CONTENTS:
- ${DMG_NAME} - macOS Disk Image (recommended)
- ${ZIP_NAME} - ZIP Archive (alternative)
- SHA256 checksums for verification

DISTRIBUTION METHODS:

1. DMG (Recommended):
   - Users can drag Clippo.app to Applications
   - Includes README and Applications shortcut
   - Standard macOS distribution format

2. ZIP:
   - Extract and copy Clippo.app to Applications
   - Simpler for some users

IMPORTANT NOTES:

⚠️  CODE SIGNING:
This build is NOT code-signed. Users will see:
"Clippo cannot be opened because the developer cannot be verified"

WORKAROUND FOR USERS:
1. Right-click on Clippo.app
2. Select "Open"
3. Click "Open" in the dialog
4. macOS will remember this choice

OR users can run in Terminal:
  xattr -cr /Applications/Clippo.app

TO ADD CODE SIGNING (requires Apple Developer account):
1. Get Developer ID certificate from Apple
2. Run: codesign --deep --force --verify --verbose \\
        --sign "Developer ID Application: Your Name" \\
        Clippo.app
3. Notarize with Apple (required for macOS 10.15+)

DISTRIBUTION CHANNELS:
- GitHub Releases (attach DMG and ZIP)
- Direct download from website
- Email to beta testers

REQUIREMENTS:
- macOS 12.0 or later
- Accessibility permission (for auto-paste)

BUILD DATE: $(date)
BUNDLE ID: com.clippo.macos
VERSION: ${VERSION}

CHECKSUMS:
$(cat ${ZIP_NAME}.sha256)
$(cat ${DMG_NAME}.sha256)

EOF

echo ""
echo "✅ Distribution build complete!"
echo ""
echo "📦 Distribution files created in: $DIST_DIR/"
echo ""
ls -lh "$DIST_DIR"
echo ""
echo "📋 Next steps:"
echo "   1. Test the DMG/ZIP on a clean Mac"
echo "   2. Upload to GitHub Releases or your website"
echo "   3. Share DISTRIBUTION_INFO.txt with users"
echo "   4. (Optional) Add code signing for better user experience"
echo ""
