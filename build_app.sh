#!/bin/bash

# Exit on error
set -e

APP_NAME="Clippo"
SOURCE_ICON="Sources/Resources/clippo-logo.icon/Assets/Frame 98.png"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"

echo "🚀 Starting build process for $APP_NAME..."

# 1. Build the project
echo "🛠️  Building Swift project..."
swift build -c release -Xswiftc -DRELEASE

# 2. Create App Bundle Structure
echo "📂 Creating App Bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Copy Executable
echo "COPY Copying executable..."
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# 4. Generate App Icon
echo "🎨 Generating App Icon..."
if [ -f "$SOURCE_ICON" ]; then
    ICONSET_DIR="Clippo.iconset"
    mkdir -p "$ICONSET_DIR"
    
    # Resize images
    sips -z 16 16     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
    sips -z 32 32     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
    sips -z 64 64     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
    sips -z 128 128   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
    sips -z 256 256   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
    sips -z 512 512   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
    sips -z 1024 1024 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null
    
    # Convert to icns
    iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    
    # Cleanup
    rm -rf "$ICONSET_DIR"
    echo "✅ App Icon created."
else
    echo "⚠️  Warning: Source icon not found at $SOURCE_ICON"
fi

# 5. Copy other resources
echo "📦 Copying resources..."
# Copy the Resources directory content to the bundle resources
cp -r Sources/Resources/* "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
# Remove the raw icon folder from the bundle to save space
rm -rf "$APP_BUNDLE/Contents/Resources/clippo-logo.icon"

# 6. Create Info.plist
echo "📝 Creating Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.clippo.macos</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Clippo needs access to simulate paste operations to automatically paste clipboard content into other applications.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
</dict>
</plist>
EOF

echo "✅ Build Complete!"
echo "🎉 App is ready at: $APP_BUNDLE"
