#!/bin/bash

# Exit on error
set -e

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide a version number (e.g., 1.0.0)"
    echo "Usage: ./release.sh <version>"
    exit 1
fi

VERSION="$1"
APP_NAME="Clippo"
DIST_ROOT="temp_dist"
VERSION_DIR="$DIST_ROOT/v$VERSION"
DMG_NAME="$APP_NAME-$VERSION.dmg"

echo "🚀 Preparing release for version $VERSION..."

# 1. Build the app
echo "🛠️  Building app..."
./build_app.sh

# 2. Create version directory
echo "📂 Creating release directory: $VERSION_DIR"
mkdir -p "$VERSION_DIR"

# 3. Create DMG using create-dmg
echo "💿 Creating DMG..."
if ! command -v create-dmg &> /dev/null; then
    echo "⚠️  create-dmg not found, using npx..."
    npx create-dmg "$APP_NAME.app" "$VERSION_DIR" --no-code-sign --dmg-title="$APP_NAME $VERSION"
else
    create-dmg "$APP_NAME.app" "$VERSION_DIR" --no-code-sign --dmg-title="$APP_NAME $VERSION"
fi

# 4. Rename DMG to standard format if needed
# create-dmg usually names it "App Name Version.dmg" or similar
# We want "Clippo-1.0.0.dmg"
GENERATED_DMG="$VERSION_DIR/$APP_NAME $VERSION.dmg"
TARGET_DMG="$VERSION_DIR/$DMG_NAME"

if [ -f "$GENERATED_DMG" ]; then
    mv "$GENERATED_DMG" "$TARGET_DMG"
    echo "✅ Renamed DMG to $DMG_NAME"
fi

# 5. Copy App Bundle to release folder (optional, but good for zipping)
echo "📦 Copying App Bundle..."
cp -r "$APP_NAME.app" "$VERSION_DIR/"

# 6. Create ZIP (optional)
echo "🤐 Creating ZIP..."
cd "$VERSION_DIR"
zip -r "$APP_NAME-$VERSION.zip" "$APP_NAME.app" -x "*.DS_Store"
cd - > /dev/null

echo ""
echo "✅ Release v$VERSION ready!"
echo "📂 Location: $VERSION_DIR"
echo "   - $DMG_NAME"
echo "   - $APP_NAME-$VERSION.zip"
echo "   - $APP_NAME.app"
