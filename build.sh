#!/usr/bin/env bash
# Builds build/Precise EN.app (the Mac app) and build/precise-en (the CLI).
#
# The apps' API URL and token, Apple team and bundle ID come from ~/.config/precise-en/config.json,
# through the git-ignored apps/Secrets.xcconfig that apps/configure.sh writes.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd "$root"

"$root/apps/configure.sh"
xcodebuild -project apps/PreciseEN.xcodeproj -scheme PreciseENMac -configuration Release \
    -derivedDataPath build/DerivedData -quiet build
rm -rf "build/Precise EN.app"
ditto "build/DerivedData/Build/Products/Release/Precise EN.app" "build/Precise EN.app"

swift build -c release --product precise-en
cp "$(swift build -c release --show-bin-path)/precise-en" build/precise-en

echo "Built $root/build/Precise EN.app and $root/build/precise-en"
