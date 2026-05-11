#!/usr/bin/env bash
# build.sh — compile BugHunter.app with plain swiftc (no Xcode required)
# Run from the mac/ directory: cd mac && ./build.sh
set -euo pipefail

APP=BugHunter.app
MACOS_DIR="$APP/Contents/MacOS"
RESOURCES_DIR="$APP/Contents/Resources"

echo "→ Cleaning old build..."
rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "→ Copying Info.plist..."
cp Resources/Info.plist "$APP/Contents/"

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
    -O \
    -o "$MACOS_DIR/BugHunter"

echo "→ Ad-hoc signing..."
codesign --force --deep --sign - "$APP"

echo "→ Stripping quarantine flag..."
xattr -cr "$APP" 2>/dev/null || true

echo ""
echo "✓ Built: $APP"
echo ""
echo "Run with:"
echo "  open $APP"
echo ""
echo "If macOS blocks the app:"
echo "  Right-click → Open   (first launch)"
echo "  or: xattr -d com.apple.quarantine $APP"
