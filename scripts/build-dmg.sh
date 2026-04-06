#!/bin/bash
# Builds ClaudeBar.app and packages it into a .dmg for distribution.
# Run from the root of the repository: ./scripts/build-dmg.sh
#
# Prerequisites:
#   - Xcode command-line tools installed (xcode-select --install)
#
# Output: build/ClaudeBar.dmg

set -euo pipefail

VERSION=${GITHUB_REF_NAME:-"dev"}
BUILD_DIR="build"
APP_NAME="ClaudeBar"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

echo "==> Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Building universal binary (arm64 + x86_64)..."
swift build -c release --arch arm64 --arch x86_64

BINARY_PATH=".build/apple/Products/Release/$APP_NAME"
if [ ! -f "$BINARY_PATH" ]; then
  echo "ERROR: Binary not found at $BINARY_PATH"
  exit 1
fi

echo "==> Assembling .app bundle..."
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp "$BINARY_PATH" "$APP_PATH/Contents/MacOS/$APP_NAME"

# Write Info.plist — required for macOS to treat the binary as a GUI app.
# LSUIElement hides ClaudeBar from the dock (it lives in the menu bar instead).
cat > "$APP_PATH/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClaudeBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.claudebar.ClaudeBar</string>
    <key>CFBundleName</key>
    <string>ClaudeBar</string>
    <key>CFBundleDisplayName</key>
    <string>ClaudeBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Creating .dmg..."
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$APP_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo ""
echo "Done! Distributable DMG is at: $DMG_PATH"
echo ""
echo "NOTE: Users on other Macs may need to right-click the app and choose Open"
echo "on first launch if it is not signed with an Apple Developer ID certificate."
