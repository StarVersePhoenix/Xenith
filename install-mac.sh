#!/bin/bash
# Xenith Studio installer for Mac (Apple silicon, macOS 15 or newer).
# Run by the member's own Claude (see INSTALL.md) or by hand:  bash install-mac.sh
# It downloads the latest Xenith Studio from this repository's Releases, checks the download, puts the app in Applications,
# opens it and checks that it really started. It never asks for an admin password, never uses sudo and only writes:
#   /Applications/Xenith Studio.app (or ~/Applications when /Applications is not writable), ~/Xenith (the app's own folder)
#   and a temporary folder that it removes at the end.
# Every line it prints starts with "XENITH:" so Claude can read the result. The last line is XENITH: DONE or XENITH: STOP.
set -u

REPO="StarVersePhoenix/xenith"
ASSET="Xenith-Studio-mac.dmg"
URL="https://github.com/$REPO/releases/latest/download/$ASSET"
APP_NAME="Xenith Studio.app"
MIN_MACOS=15
NEED_GB=8

say()  { echo "XENITH: $*"; }
stop() { say "STOP: $*"; [ -n "${TMP:-}" ] && rm -rf "$TMP"; exit 1; }

# 1. The Mac
[ "$(uname -s)" = "Darwin" ] || stop "This installer is for a Mac. Windows comes later."
[ "$(uname -m)" = "arm64" ] || stop "Xenith Studio needs a Mac with Apple silicon (M1 or newer). This Mac has an Intel chip."
MAJOR=$(sw_vers -productVersion | cut -d. -f1)
[ "${MAJOR:-0}" -ge "$MIN_MACOS" ] || stop "Xenith Studio needs macOS $MIN_MACOS or newer. This Mac has macOS $(sw_vers -productVersion). Update macOS in System Settings, then try again."
FREE_GB=$(df -g "$HOME" | awk 'NR==2 {print $4}')
[ "${FREE_GB:-0}" -ge "$NEED_GB" ] || stop "Xenith Studio needs about $NEED_GB GB free space. This Mac has ${FREE_GB} GB free. Free some space, then try again."
say "Mac check passed: Apple silicon, macOS $(sw_vers -productVersion), ${FREE_GB} GB free."

# 2. Download and check
TMP=$(mktemp -d "${TMPDIR:-/tmp}/xenith-install.XXXXXX") || stop "Could not make a temporary folder."
say "Downloading Xenith Studio (about 400 MB)..."
curl -fL --retry 3 --connect-timeout 20 -o "$TMP/$ASSET" "$URL" || stop "The download failed. Check the internet connection, then try again."
curl -fsL --retry 3 -o "$TMP/$ASSET.sha256" "$URL.sha256" || stop "Could not download the check file for the installer."
WANT=$(awk '{print $1}' "$TMP/$ASSET.sha256")
HAVE=$(shasum -a 256 "$TMP/$ASSET" | awk '{print $1}')
[ -n "$WANT" ] && [ "$WANT" = "$HAVE" ] || stop "The download is damaged (its check did not match). Try again."
say "Download checked."

# 3. Quit a running Xenith, then install
if pgrep -f "$APP_NAME/Contents/MacOS" >/dev/null 2>&1; then
  say "Xenith Studio is open. Closing it to install the new version..."
  osascript -e 'tell application "Xenith Studio" to quit' >/dev/null 2>&1
  sleep 3
fi
MNT="$TMP/mnt"
mkdir -p "$MNT"
hdiutil attach -nobrowse -readonly -quiet -mountpoint "$MNT" "$TMP/$ASSET" || stop "Could not open the installer file."
[ -d "$MNT/$APP_NAME" ] || { hdiutil detach -quiet "$MNT"; stop "The installer file does not contain Xenith Studio."; }
DEST="/Applications"
[ -w "$DEST" ] || { DEST="$HOME/Applications"; mkdir -p "$DEST"; }
if [ -d "$DEST/$APP_NAME" ]; then
  mv "$DEST/$APP_NAME" "$TMP/old-app" 2>/dev/null || { hdiutil detach -quiet "$MNT"; stop "Could not replace the old Xenith Studio in $DEST. Close it and try again."; }
fi
ditto "$MNT/$APP_NAME" "$DEST/$APP_NAME" || { hdiutil detach -quiet "$MNT"; [ -d "$TMP/old-app" ] && mv "$TMP/old-app" "$DEST/$APP_NAME"; stop "Could not copy Xenith Studio into $DEST."; }
hdiutil detach -quiet "$MNT" >/dev/null 2>&1
# The app was downloaded by this script and its check matched, so the download mark is removed from this one app only.
# That way macOS does not ask the member to go to Privacy & Security and press Open Anyway.
xattr -dr com.apple.quarantine "$DEST/$APP_NAME" 2>/dev/null
VERSION=$(defaults read "$DEST/$APP_NAME/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "?")
say "Installed Xenith Studio $VERSION in $DEST."

# 4. Open and check it really started
LOG="$HOME/Xenith/logs/serve.log"
START_LINES=$( [ -f "$LOG" ] && wc -l < "$LOG" || echo 0 )
rm -f "$HOME/Xenith/logs/last-problem.txt" 2>/dev/null
open "$DEST/$APP_NAME" || stop "macOS would not open Xenith Studio."
say "Opening Xenith Studio. The first start takes up to a minute..."
URL_SEEN=""
for i in $(seq 1 90); do
  sleep 2
  if [ -f "$HOME/Xenith/logs/last-problem.txt" ]; then
    stop "Xenith Studio could not start: $(cat "$HOME/Xenith/logs/last-problem.txt")"
  fi
  if [ -f "$LOG" ]; then
    URL_SEEN=$(tail -n +"$((START_LINES + 1))" "$LOG" | grep -o 'is running at http://127.0.0.1:[0-9]*' | tail -1 | awk '{print $4}')
    [ -n "$URL_SEEN" ] && break
  fi
done
[ -n "$URL_SEEN" ] || stop "Xenith Studio did not finish starting within 3 minutes. Look at its window, or send the file ~/Xenith/logs/serve.log to support."
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$URL_SEEN" || echo 000)
[ "$CODE" != "000" ] || stop "Xenith Studio started but does not answer yet. Look at its window."
rm -rf "$TMP"
say "Xenith Studio $VERSION is open and running."
say "DONE"
