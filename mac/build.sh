#!/usr/bin/env bash
# build.sh - compile, sign, and optionally package BugHunter.app with plain
# swiftc (no Xcode project required).
#
# Run from the mac/ directory:
#   ./build.sh
#   ./build.sh --package
#
# Optional:
#   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build.sh --package
set -euo pipefail

APP=BugHunter.app
MACOS_DIR="$APP/Contents/MacOS"
RESOURCES_DIR="$APP/Contents/Resources"
BUILD_DIR=build
MODULE_CACHE_DIR="$BUILD_DIR/ModuleCache"
ZIP=../BugHunter-mac.zip
PACKAGE=0

for arg in "$@"; do
    case "$arg" in
        --package)
            PACKAGE=1
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: $0 [--package]" >&2
            exit 2
            ;;
    esac
done

echo "→ Cleaning old build..."
rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$MODULE_CACHE_DIR"

echo "→ Copying Info.plist..."
cp Resources/Info.plist "$APP/Contents/"
cp Resources/*.icns "$RESOURCES_DIR/"

echo "→ Compiling Swift sources..."
swiftc \
    Sources/main.swift \
    Sources/AppDelegate.swift \
    Sources/OverlayWindow.swift \
    Sources/Bug.swift \
    Sources/BugRenderer.swift \
    Sources/BugView.swift \
    Sources/BugController.swift \
    Sources/SoundManager.swift \
    -framework AppKit \
    -framework CoreGraphics \
    -module-cache-path "$MODULE_CACHE_DIR" \
    -O \
    -o "$MACOS_DIR/BugHunter"

echo "→ Clearing local quarantine metadata..."
xattr -cr "$APP" 2>/dev/null || true

SIGNING_IDENTITY="${CODESIGN_IDENTITY:--}"
if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    echo "→ Signing app bundle with an ad-hoc signature..."
    codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP"
else
    echo "→ Signing app bundle with: $SIGNING_IDENTITY"
    codesign --force --deep --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP"
fi

codesign --verify --deep --strict --verbose=2 "$APP"

if [[ "$PACKAGE" -eq 1 ]]; then
    echo "→ Packaging $ZIP..."
    rm -f "$ZIP"
    COPYFILE_DISABLE=1 ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl "$APP" "$ZIP"
fi

echo ""
echo "✓ Built: $APP"
if [[ "$PACKAGE" -eq 1 ]]; then
    echo "✓ Packaged: $ZIP"
fi
echo ""
echo "Run with:"
echo "  open $APP"
echo ""
if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    echo "This build uses an ad-hoc signature. If macOS blocks the downloaded app,"
    echo "right-click the app icon and choose Open on first launch."
else
    echo "For public distribution, notarize and staple the app before release."
fi
