#!/bin/bash
# Builds ClaudeBar.app and packages it into a .dmg for distribution.
# Run from the root of the repository: ./scripts/build-dmg.sh
#
# Prerequisites:
#   - Xcode command-line tools installed (xcode-select --install)
#   - The project opened in Xcode at least once (to resolve package dependencies)
#
# Output: build/ClaudeBar.dmg

set -euo pipefail

SCHEME="ClaudeBar"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/ClaudeBar.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
DMG_PATH="$BUILD_DIR/ClaudeBar.dmg"
EXPORT_OPTIONS="scripts/ExportOptions.plist"

echo "==> Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Archiving $SCHEME..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -archivePath "$ARCHIVE_PATH" \
  -configuration Release \
  -destination "platform=macOS" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

echo "==> Exporting .app..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

APP_PATH="$EXPORT_PATH/ClaudeBar.app"
if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: .app not found at $APP_PATH"
  exit 1
fi

echo "==> Creating .dmg..."
hdiutil create \
  -volname "ClaudeBar" \
  -srcfolder "$APP_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo ""
echo "Done! Distributable DMG is at: $DMG_PATH"
echo ""
echo "NOTE: Users on other Macs may need to right-click the app and choose Open"
echo "on first launch if it is not signed with an Apple Developer ID certificate."
