#!/usr/bin/env bash
# Builds Precise EN, replaces the copy in /Applications and launches it, and installs the
# precise-en CLI (the prompt hook) in ~/.local/bin.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
"$root/build.sh"

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$root/build/Precise EN.app/Contents/Info.plist")"
osascript -e "tell application id \"$bundle_id\" to quit" 2>/dev/null || true
# Opening the new copy while the old one is still quitting fails, so wait for it to go.
while pgrep -f "/Applications/Precise EN.app/Contents/MacOS/" >/dev/null; do sleep 0.1; done
rm -rf "/Applications/Precise EN.app"
ditto "$root/build/Precise EN.app" "/Applications/Precise EN.app"
open "/Applications/Precise EN.app"
echo "Installed /Applications/Precise EN.app"

mkdir -p "$HOME/.local/bin"
install -m 755 "$root/build/precise-en" "$HOME/.local/bin/precise-en"
echo "Installed $HOME/.local/bin/precise-en"
