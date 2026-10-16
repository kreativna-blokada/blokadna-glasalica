#!/bin/zsh
# Headless export for Play Store (AAB), App Store (Xcode project) and web (HTML5).
#
#   ./export.sh            # release: Android AAB + iOS Xcode project + web
#   ./export.sh android    # release Android AAB only
#   ./export.sh ios        # release iOS Xcode project only
#   ./export.sh web        # release web build only (serve release/build/web over HTTP)
#   ./export.sh debug      # debug Android AAB (no release keystore needed)
set -e
# Godot project is the parent of this prod/ folder; outputs go to !project/release/build (next to blokadna-glasalica).
cd "$(dirname "$0")/.."
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
OUT=../../release/build

# Release keystore secrets live in export_credentials.cfg (gitignored);
# Godot's headless mode reads them reliably only via these env vars.
cred() { grep "^$1=" export_credentials.cfg | cut -d'"' -f2; }
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$(cred keystore/release)"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$(cred keystore/release_user)"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(cred keystore/release_password)"

if pgrep -f "Godot.*--path $(pwd) --editor" >/dev/null; then
  echo "Godot editor has this project open — close it first (both write to .godot/)."; exit 1
fi
mkdir -p $OUT/android $OUT/ios $OUT/web
$GODOT --headless --import . >/dev/null 2>&1 || true

run() {  # run <mode> <preset> <output>
  rm -rf "$3"
  local log; log=$($GODOT --headless --export-$1 "$2" "$3" 2>&1) || true
  # "Unrecognized UID" is a benign race between the export and the editor's
  # filesystem scan started by --import; the export itself still succeeds.
  local errs; errs=$(echo "$log" | grep -iE '^ERROR' | grep -v 'Unrecognized UID') || true
  if [[ -n "$errs" || ! -e "$3" ]]; then echo "$log" | grep -iE 'error|fail'; echo "FAILED: $2"; exit 1; fi
  ls -lhd "$3"
}

TARGET="${1:-all}"
# the game reads [database] debug_release from the packed runtime_credentials.cfg; this only reports it
if [[ $TARGET != debug && "$(grep '^debug_release=' runtime_credentials.cfg | cut -d= -f2)" == false ]]; then
  echo "== database: PRODUCTION"
  echo "WARNING: Game is going public, so open the glasalica project (which is a debug project), go to Realtime Database → Rules, set: { \"rules\": { \".read\": false, \".write\": false } } and click Publish."
else
  echo "== database: development"
fi
case $TARGET in
  debug)       echo "== Android debug AAB";   run debug   "Android" $OUT/android/blokadna-glasalica-debug.aab ;;
  android|all) echo "== Android release AAB"; run release "Android" $OUT/android/blokadna-glasalica.aab ;;
esac
case $TARGET in
  ios|all)     echo "== iOS Xcode project";   run release "iOS"     $OUT/ios/blokadna-glasalica.xcodeproj ;;
esac
case $TARGET in
  web|all)     echo "== Web build";           rm -rf $OUT/web; mkdir -p $OUT/web; run release "Web" $OUT/web/index.html ;;
esac
echo "Done → $OUT/"
