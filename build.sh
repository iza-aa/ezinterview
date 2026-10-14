#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="$DIR/iza-quote.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

echo "🔨 Mengompilasi iza-quote..."
swiftc -O \
    "$DIR/AudioRecorder.swift" \
    "$DIR/FloatingChatApp.swift" \
    "$DIR/main.swift" \
    -o "$DIR/iza-quote"

echo "📦 Membungkus ke iza-quote.app..."
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$DIR/iza-quote" "$MACOS_DIR/iza-quote"

cat << 'PLIST' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>iza-quote</string>
    <key>CFBundleIdentifier</key>
    <string>com.iza.quote</string>
    <key>CFBundleName</key>
    <string>iza-quote</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>iza-quote memerlukan akses audio untuk merekam pertanyaan sesi Q&amp;A presentasi.</string>
</dict>
</plist>
PLIST

echo "✅ Build selesai: $APP_BUNDLE dan $DIR/iza-quote"
