#!/usr/bin/env bash
# Builds precise//en, replaces the copy in /Applications and launches it, and installs the
# precise-en CLI (the prompt hook) in ~/.local/bin.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
"$root/build.sh"

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$root/build/precise::en.app/Contents/Info.plist")"
osascript -e "tell application id \"$bundle_id\" to quit" 2>/dev/null || true
# Opening the new copy while the old one is still quitting fails, so wait for it to go.
while pgrep -f "/Applications/precise::en.app/Contents/MacOS/" >/dev/null; do sleep 0.1; done
rm -rf "/Applications/precise::en.app"
ditto "$root/build/precise::en.app" "/Applications/precise::en.app"
open "/Applications/precise::en.app"
echo "Installed /Applications/precise::en.app"

mkdir -p "$HOME/.local/bin"
install -m 755 "$root/build/precise-en" "$HOME/.local/bin/precise-en"
echo "Installed $HOME/.local/bin/precise-en"
