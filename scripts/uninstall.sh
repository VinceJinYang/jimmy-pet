#!/usr/bin/env bash
set -euo pipefail

PLIST="$HOME/Library/LaunchAgents/com.jinyang.jimmypet.plist"
launchctl unload "$PLIST" >/dev/null 2>&1 || true
rm -f "$PLIST"

killall JimmyPet >/dev/null 2>&1 || true

rm -rf "$HOME/Applications/JimmyPet.app"
defaults delete com.jinyang.jimmypet >/dev/null 2>&1 || true

echo "✓ 已卸载"
