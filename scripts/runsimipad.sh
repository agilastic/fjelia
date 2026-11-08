#!/usr/bin/env bash
# Launch Fjelia in an iPad simulator (default: iPad Pro 13-inch) for App Store screenshots.
set -euo pipefail
umask 077
# Optional per-developer settings (git-ignored): FJELIA_IPAD_SIMULATOR.
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
# Build-time credentials (see secrets.example.json); absent = services unavailable.
DEFINES=()
# Screenshots show what testers get: without the developer's own switches.
. "$(dirname "$0")/public-defines.sh"
[ -f "$(dirname "$0")/../secrets.json" ] && DEFINES+=(--dart-define-from-file="$(public_defines "$(dirname "$0")/../secrets.json")")
[ -f "$(dirname "$0")/../../fjelia-service/secrets.json" ] && DEFINES+=(--dart-define-from-file="$(public_defines "$(dirname "$0")/../../fjelia-service/secrets.json")")

usage() {
  cat <<'EOF'
Usage: fjelia/scripts/runsimipad.sh [--simulator NAME_OR_UDID] [--shots DIR] [--prepare] [-- FLUTTER_OPTIONS...]

Simulator: --simulator, or FJELIA_IPAD_SIMULATOR (set it in scripts/local.env).
Default is the newest available "iPad Pro 13-inch" simulator, which produces the
13-inch screenshots App Store Connect requires (2064 x 2752).
--shots DIR saves a screenshot to DIR each time you press Enter in a second
terminal running: fjelia/scripts/runsimipad.sh --shots DIR --only-shots
--prepare fetches dependencies and regenerates Drift sources before launch.

Screenshots can also be taken in Simulator with Cmd+S (saved to the Desktop).
Flutter controls: r = hot reload, R = hot restart, q = stop.
EOF
}

simulator="${FJELIA_IPAD_SIMULATOR:-}"
shots_dir=""
only_shots=0
prepare=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --simulator|--shots)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { usage >&2; exit 2; }
      if [ "$1" = --simulator ]; then simulator="$2"; else shots_dir="$2"; fi
      shift 2 ;;
    --only-shots) only_shots=1; shift ;;
    --prepare) prepare=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    *) usage >&2; exit 2 ;;
  esac
done
command -v xcrun >/dev/null || { echo "Xcode command line tools are missing." >&2; exit 1; }

# Resolve a name or UDID to the UDID of an available simulator; prefer the last
# (newest) match when several runtimes provide the same model.
if [ -z "$simulator" ]; then simulator="iPad Pro 13-inch"; fi
udid=$(xcrun simctl list devices available \
  | grep -F -- "$simulator" \
  | sed -nE 's/.*\(([0-9A-F-]{36})\).*/\1/p' \
  | tail -n 1)
[ -n "$udid" ] || { echo "No available simulator matches \"$simulator\" (see xcrun simctl list devices)." >&2; exit 2; }

take_shots() {
  mkdir -p "$shots_dir"
  echo "Press Enter to save a screenshot to $shots_dir, Ctrl+C to stop."
  local n=1
  while read -r _; do
    local file
    file="$shots_dir/ipad13-$(date +%Y%m%d-%H%M%S)-$n.png"
    xcrun simctl io "$udid" screenshot "$file" >/dev/null && echo "Saved $file"
    n=$((n + 1))
  done
}
if [ "$only_shots" -eq 1 ]; then
  [ -n "$shots_dir" ] || { echo "--only-shots needs --shots DIR." >&2; exit 2; }
  take_shots
  exit 0
fi

command -v flutter >/dev/null || { echo "Flutter is not on PATH." >&2; exit 1; }
cd "$(dirname "$0")/.."
bash scripts/ensure-metal-toolchain.sh
python3 scripts/trust-mlx-plugin.py
# Booting an already booted simulator fails harmlessly.
xcrun simctl boot "$udid" 2>/dev/null || true
# Show the window when Simulator.app is installed; without it the simulator
# runs headless and screenshots still work through --shots.
open -a Simulator --args -CurrentDeviceUDID "$udid" 2>/dev/null \
  || echo "Simulator.app not found; running headless (use --shots for screenshots)."
# Clean status bar for screenshots: 9:41, full battery and signal.
xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged \
  --batteryLevel 100 --wifiBars 3 --cellularMode active --cellularBars 4 || true
echo "Simulator: $simulator ($udid)"
if [ "$prepare" -eq 1 ]; then
  flutter pub get
  flutter pub run build_runner build
fi
# Simulators only run debug builds; the debug banner is disabled in main.dart.
flutter run --debug --no-dds -d "$udid" ${DEFINES[@]+"${DEFINES[@]}"} "$@"
