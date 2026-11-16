# Screenshots

Every screenshot lives in `docs/assets/screenshots/`: six single screens, and the two images the README shows, `mac.png` and `iphone.png`, which combine them. They are taken from the real apps running against a local copy of your word list, so nothing on your live list is rated, opened or changed.

| File | Shows |
|---|---|
| `mac-review.png` | The Mac window with a card |
| `mac-review-answer.png` | The same card with its answer |
| `iphone-review.png` | The iPhone's Review |
| `iphone-review-answer.png` | The answer |
| `iphone-words.png` | Words |
| `iphone-stats.png` | Stats |
| `mac.png` | Both Mac screens side by side, for the README |
| `iphone.png` | All four iPhone screens side by side, for the README |

## What they may show

Every saved word quotes your own prompt under *You wrote* and *Precisely*. The screenshots open only one card, the chosen word's, and [`seed.py`](screenshots/seed.py) replaces that card's phrase and rewrite with invented ones in the local copy. Words and Stats show only words, definitions and counts. Before committing, look at every image for anything else from your prompts.

Pick an `advanced` or `rare` word for the card, short enough to fit the iPhone on one line.

## Requirements

- Xcode, with an iPhone 17 Pro simulator.
- `pngquant` (`brew install pngquant`) and Python with Pillow.
- Accessibility permission for your terminal (System Settings → Privacy & Security → Accessibility), so `osascript` can press keys and size the window.

## 1. Run the Worker on a copy of your list

Run each block from the repository root. The word, phrase and rewrite are the card's; the rewrite must use the word.

```sh
shots=/tmp/precise-en-shots
rm -rf $shots && mkdir -p $shots
cd worker
npx wrangler d1 migrations apply precise-en --local --persist-to $shots/d1
npx wrangler d1 execute precise-en --remote --json --command "SELECT * FROM words" \
  | python3 ../docs/screenshots/seed.py ephemeral \
      "spun up just for the test run and thrown away afterwards" \
      "Give each test run an ephemeral database." \
  > $shots/seed.sql
npx wrangler d1 execute precise-en --local --persist-to $shots/d1 --file $shots/seed.sql
cd ..
```

Then, in a second terminal, leave the local Worker running:

```sh
cd worker && npx wrangler dev --local --persist-to /tmp/precise-en-shots/d1 --port 8787 --var TOKEN:screenshots
```

## 2. Build both apps against it

The apps take their URL and token from `apps/Secrets.xcconfig`, which `apps/configure.sh` writes from your config. Point it at the local Worker for these builds, then write it again from your config.

```sh
shots=/tmp/precise-en-shots
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
apps/configure.sh
sed -i '' -e 's|^PRECISE_EN_URL = .*|PRECISE_EN_URL = http:/$()/localhost:8787|' \
          -e 's|^PRECISE_EN_TOKEN = .*|PRECISE_EN_TOKEN = screenshots|' apps/Secrets.xcconfig
xcodebuild -project apps/PreciseEN.xcodeproj -scheme PreciseENMac -configuration Release \
    -derivedDataPath $shots/mac -quiet build
xcodebuild -project apps/PreciseEN.xcodeproj -scheme PreciseENiOS -configuration Debug \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath $shots/ios -quiet build CODE_SIGNING_ALLOWED=NO
apps/configure.sh
```

## 3. The Mac window

The screenshot build shares the installed app's bundle ID, so quit the installed app first. Opening the app a second time opens its window. The window is captured at 900 × 640 points, its default size.

```sh
shots=/tmp/precise-en-shots
out=docs/assets/screenshots
mkdir -p $out
app="$shots/mac/Build/Products/Release/precise::en.app"
pkill -f "/Applications/precise::en.app/Contents/MacOS"
open "$app"; sleep 5; open "$app"; sleep 3
osascript -e 'tell application "System Events" to tell process "precise::en"' \
          -e 'set frontmost to true' -e 'set size of window 1 to {900, 640}' -e 'end tell'
sleep 1
window=$(swift docs/screenshots/window-id.swift)
screencapture -x -o -l $window $out/mac-review.png
osascript -e 'tell application "System Events" to key code 49'   # Space: Show Answer
sleep 2
screencapture -x -o -l $window $out/mac-review-answer.png
pkill -f "$app/Contents/MacOS"
open "/Applications/precise::en.app"
```

## 4. The iPhone

```sh
shots=/tmp/precise-en-shots
out=docs/assets/screenshots
app="$shots/ios/Build/Products/Debug-iphonesimulator/Precise EN.app"
bundle=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app/Info.plist")
device=$(xcrun simctl list devices available | grep -m1 "iPhone 17 Pro (" | grep -oE '[0-9A-F-]{36}')
xcrun simctl shutdown $device; xcrun simctl boot $device; xcrun simctl bootstatus $device
xcrun simctl ui $device appearance dark
xcrun simctl status_bar $device override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charging --batteryLevel 100
xcrun simctl install $device "$app"
open -a Simulator; sleep 4
xcrun simctl launch $device $bundle; sleep 8
xcrun simctl io $device screenshot $out/iphone-review.png
osascript -e 'tell application "Simulator" to activate' -e 'delay 1' \
          -e 'tell application "System Events" to key code 49'   # Space: Show Answer
sleep 2
xcrun simctl io $device screenshot $out/iphone-review-answer.png
```

Click **Words** in the Simulator's tab bar, then:

```sh
xcrun simctl io $device screenshot $out/iphone-words.png
```

Click **Stats**, then:

```sh
xcrun simctl io $device screenshot $out/iphone-stats.png
xcrun simctl uninstall $device $bundle
xcrun simctl status_bar $device clear
xcrun simctl shutdown $device
```

## 5. Combine and clean up

```sh
python3 docs/screenshots/compose.py docs/assets/screenshots
pngquant --quality 80-95 --speed 1 --force --ext .png docs/assets/screenshots/*.png
```

Stop `wrangler dev`, then delete the local copy: it holds every word you saved, with your prompts.

```sh
rm -rf /tmp/precise-en-shots
```
