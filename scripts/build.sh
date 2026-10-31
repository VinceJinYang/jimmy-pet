#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP="JimmyPet.app"
BIN="JimmyPet"

echo "→ 编译"
mkdir -p .cache
swiftc -O -module-cache-path "$PWD/.cache" -o "$BIN" desktop/main.swift

echo "→ 打包"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/JimmyPet"
cp desktop/Info.plist "$APP/Contents/Info.plist"
cp assets/pose_*.png "$APP/Contents/Resources/"
cp assets/quotes.json "$APP/Contents/Resources/"
chmod +x "$APP/Contents/MacOS/JimmyPet"

echo "→ 签名（ad-hoc）"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "✓ 完成：$PWD/$APP"
