#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Mora"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/.build/xcode-release-derived"
RELEASE_DIR="$ROOT_DIR/dist/release"
STAGING_DIR="$RELEASE_DIR/dmg-staging"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Mora/Info.plist")"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.dmg"

cd "$ROOT_DIR"

rm -rf "$RELEASE_DIR"
mkdir -p "$STAGING_DIR"

/usr/bin/xcrun xcodebuild \
  -project Mora.xcodeproj \
  -scheme "$APP_NAME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

/usr/bin/ditto "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
/bin/ln -s /Applications "$STAGING_DIR/Applications"

/usr/bin/hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

/usr/bin/shasum -a 256 "$DMG_PATH"
