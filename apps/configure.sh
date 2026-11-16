#!/usr/bin/env bash
# Writes Secrets.xcconfig from ~/.config/precise-en/config.json and generates PreciseEN.xcodeproj.
# Run it before opening the project in Xcode; build.sh and install-iphone.sh run it themselves.
set -euo pipefail

apps="$(cd "$(dirname "$0")" && pwd)"
config="$HOME/.config/precise-en/config.json"

umask 077
# xcconfig reads // as the start of a comment, so the URL's // is written as /$()/.
python3 - "$config" "$apps/Secrets.xcconfig" <<'PY'
import json, sys
path, output = sys.argv[1], sys.argv[2]
keys = ["url", "token", "apple_team_id", "bundle_id"]
try:
    with open(path) as file:
        config = json.load(file)
except FileNotFoundError:
    sys.exit(f"configure.sh: {path} does not exist. Write it with {', '.join(keys)}, as Setup in README.md shows.")
except json.JSONDecodeError as error:
    sys.exit(f"configure.sh: {path} is not valid JSON: {error}")
missing = [key for key in keys if not config.get(key)]
if missing:
    sys.exit(f"configure.sh: {path} has no {', '.join(missing)}. Setup in README.md shows every key.")
with open(output, "w") as file:
    file.write("PRECISE_EN_URL = " + config["url"].replace("//", "/$()/") + "\n")
    file.write("PRECISE_EN_TOKEN = " + config["token"] + "\n")
    file.write("DEVELOPMENT_TEAM = " + config["apple_team_id"] + "\n")
    file.write("PRODUCT_BUNDLE_IDENTIFIER = " + config["bundle_id"] + "\n")
PY
xcodegen generate --spec "$apps/project.yml" --quiet
