#!/usr/bin/env bash
# Writes Secrets.xcconfig from ~/.config/precise-en/config.json and generates PreciseEN.xcodeproj.
# Run it before opening the project in Xcode; build.sh and install-iphone.sh run it themselves.
set -euo pipefail

apps="$(cd "$(dirname "$0")" && pwd)"
config="$HOME/.config/precise-en/config.json"

umask 077
# xcconfig reads // as the start of a comment, so the URL's // is written as /$()/.
python3 - "$config" > "$apps/Secrets.xcconfig" <<'PY'
import json, sys
path = sys.argv[1]
keys = ["url", "token", "apple_team_id", "bundle_id"]
try:
    with open(path) as file:
        config = json.load(file)
except FileNotFoundError:
    sys.exit(f"configure.sh: {path} does not exist. Write it with {', '.join(keys)}, as Setup in README.md shows.")
missing = [key for key in keys if not config.get(key)]
if missing:
    sys.exit(f"configure.sh: {path} has no {', '.join(missing)}. Setup in README.md shows every key.")
print("PRECISE_EN_URL = " + config["url"].replace("//", "/$()/"))
print("PRECISE_EN_TOKEN = " + config["token"])
print("DEVELOPMENT_TEAM = " + config["apple_team_id"])
print("PRODUCT_BUNDLE_IDENTIFIER = " + config["bundle_id"])
PY
xcodegen generate --spec "$apps/project.yml" --quiet
