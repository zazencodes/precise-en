#!/usr/bin/env bash
# Builds the iPhone app and installs it on the paired iPhone. The iPhone must be unlocked and
# connected by cable or on the same network.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd "$root"

devices="$(mktemp)"
xcrun devicectl list devices --quiet --json-output "$devices"
device="$(python3 - "$devices" <<'PY'
import json, sys
devices = json.load(open(sys.argv[1]))["result"]["devices"]
phones = [d for d in devices
          if d["hardwareProperties"]["platform"] == "iOS"
          and d["connectionProperties"]["pairingState"] == "paired"
          and d["connectionProperties"].get("tunnelState") != "unavailable"]
if len(phones) != 1:
    sys.exit(f"expected one available paired iPhone, found {len(phones)}: run `xcrun devicectl list devices`")
print(phones[0]["identifier"])
PY
)"
rm "$devices"

"$root/apps/configure.sh"
xcodebuild -project apps/PreciseEN.xcodeproj -scheme PreciseENiOS -configuration Release \
    -destination "generic/platform=iOS" -derivedDataPath build/DerivedData -allowProvisioningUpdates -quiet build
xcrun devicectl device install app --device "$device" "build/DerivedData/Build/Products/Release-iphoneos/Precise EN.app"
echo "Installed precise//en on the iPhone"
