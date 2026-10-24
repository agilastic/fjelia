#!/usr/bin/env bash
# Launch Fjelia on a physical iPhone with hot reload and live logs.
set -euo pipefail
umask 077
# Optional per-developer settings (git-ignored): FJELIA_IOS_DEVICE, FJELIA_TEAM_ID.
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
# Build-time credentials (see secrets.example.json); absent = services unavailable.
DEFINES=()
[ -f "$(dirname "$0")/../secrets.json" ] && DEFINES+=(--dart-define-from-file=secrets.json)

usage() {
  cat <<'EOF'
Usage: fjelia/scripts/dev-ios.sh [--device ID_OR_NAME] [--log FILE] [--prepare] [--release] [-- FLUTTER_OPTIONS...]

Device: --device, or FJELIA_IOS_DEVICE (set it in scripts/local.env).
Starts a debug build with DDS disabled; logs appear live and are saved to a
unique temporary file. --log chooses a file instead (overwritten each run).
--prepare fetches dependencies and regenerates Drift sources before launch.
--release runs a release build instead (no hot reload; use it to test what testers get).

Flutter controls: r = hot reload, R = hot restart, q = stop, d = detach.
The iPhone must be unlocked, paired, have Developer Mode enabled, and trust your
developer profile. Signing uses the account configured in Xcode.
EOF
}

device="${FJELIA_IOS_DEVICE:-}"
log_file=""
prepare=0
mode=--debug
while [ "$#" -gt 0 ]; do
  case "$1" in
    --device|--log)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { usage >&2; exit 2; }
      if [ "$1" = --device ]; then device="$2"; else log_file="$2"; fi
      shift 2 ;;
    --prepare) prepare=1; shift ;;
    --release) mode=--release; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    *) usage >&2; exit 2 ;;
  esac
done
command -v flutter >/dev/null || { echo "Flutter is not on PATH." >&2; exit 1; }
[ -n "$device" ] || { echo "No device: pass --device or set FJELIA_IOS_DEVICE (see flutter devices)." >&2; exit 2; }
if [ -z "$log_file" ]; then
  log_file=$(mktemp "${TMPDIR:-/tmp}/fjelia-iphone-debug.XXXXXX")
else
  # Resolve the caller's path before entering the app directory.
  case "$log_file" in /*) ;; *) log_file="$PWD/$log_file" ;; esac
  : > "$log_file"
fi
cd "$(dirname "$0")/.."
# flutter run cannot pass xcodebuild settings, so hand the signing team to Xcode
# through a git-ignored xcconfig that Debug/Release/Profile include.
if [ -n "${FJELIA_TEAM_ID:-}" ]; then
  printf 'DEVELOPMENT_TEAM = %s\n' "$FJELIA_TEAM_ID" > ios/Flutter/Local.xcconfig
fi
echo "Device: $device"
echo "Logs: $log_file"
if [ "$prepare" -eq 1 ]; then
  flutter pub get
  flutter pub run build_runner build
fi
# Keep stdin attached for Flutter's interactive hot reload commands. pipefail
# preserves Flutter's exit status if launch, signing, or connection fails.
flutter run "$mode" --no-dds -d "$device" ${DEFINES[@]+"${DEFINES[@]}"} "$@" 2>&1 | tee "$log_file"
