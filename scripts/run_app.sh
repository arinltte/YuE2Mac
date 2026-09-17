#!/bin/zsh
# run_app.sh — builds YuE2Mac in Release and launches it DIRECTLY (no Xcode debugger).
#
# Why this matters: running an app with Xcode's Play button spawns `lldb-rpc-server`,
# Xcode's debug helper. It mirrors the app's memory and stays resident, which can add
# gigabytes to what Activity Monitor shows and leaves a process behind after you finish.
# Launching the built .app directly never starts it — memory stays lean and is fully
# released as soon as a generation's engine process exits.
#
#   bash scripts/run_app.sh
set -e
cd "$(dirname "$0")/.."

echo "▸ Building Release…"
xcodebuild -project YuE2Mac.xcodeproj -scheme YuE2Mac -configuration Release build -quiet

APP="$(xcodebuild -showBuildSettings -configuration Release 2>/dev/null \
        | awk '/ BUILT_PRODUCTS_DIR =/{print $3; exit}')/YuE2Mac.app"
# DERIVED_DATA path may contain no spaces here, but use a robust fallback:
[ -d "$APP" ] || APP="$(find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 6 -name YuE2Mac.app -type d 2>/dev/null | head -1)"
if [ ! -d "$APP" ]; then
  echo "❌ App bundle not found. Build first."; exit 1
fi

LOG="${TMPDIR:-/tmp}/yue2mac_launch.log"
echo "▸ Launching $APP"
nohup open "$APP" >/dev/null 2>&1 &
echo "  (lldb-rpc-server will NOT be involved.)"