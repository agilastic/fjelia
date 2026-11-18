#!/usr/bin/env bash
# Launch Fjelia on an Android phone over adb with hot reload and live logs.
set -euo pipefail
umask 077
# Optional per-developer settings (git-ignored): FJELIA_ANDROID_DEVICE.
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
# Build-time credentials (see secrets.example.json); absent = services unavailable.
DEFINES=()
[ -f "$(dirname "$0")/../secrets.json" ] && DEFINES+=(--dart-define-from-file=secrets.json)
[ -f "$(dirname "$0")/../../fjelia-service/secrets.json" ] && DEFINES+=(--dart-define-from-file=../fjelia-service/secrets.json)
# Like dev-ios.sh, this launcher enables Settings > System > Developer.
DEFINES+=(--dart-define=FJELIA_DEVELOPER_MENU=true)

usage() {
  cat <<'EOF'
Usage: fjelia/scripts/dev-android.sh [--device ID] [--log FILE] [--prepare] [--release] [--legacy] [--ignore-certs] [-- FLUTTER_OPTIONS...]

Device: --device, FJELIA_ANDROID_DEVICE (set it in scripts/local.env), or the
only phone adb lists. Starts a debug build with DDS disabled; logs appear live
and are saved to a unique temporary file. --log chooses a file instead
(overwritten each run).
--prepare fetches dependencies and regenerates Drift sources before launch.
--release runs a release build instead (no hot reload; R8 shrinking as shipped).
--legacy builds with minSdk 24 for Android 7 test phones. Health Connect
(Android 9+) cannot work there; never hand out such a build.
--ignore-certs (with --legacy only) accepts any TLS certificate
(FJELIA_IGNORE_CERTS): Android 7.0's root store no longer trusts Let's Encrypt.

Flutter controls: r = hot reload, R = hot restart, q = stop, d = detach.
The phone needs USB debugging enabled and this Mac allowed (adb devices).
EOF
}

device="${FJELIA_ANDROID_DEVICE:-}"
log_file=""
prepare=0
mode=--debug
legacy=()
ignore_certs=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --device|--log)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { usage >&2; exit 2; }
      if [ "$1" = --device ]; then device="$2"; else log_file="$2"; fi
      shift 2 ;;
    --prepare) prepare=1; shift ;;
    --release) mode=--release; shift ;;
    --legacy) legacy=(-P fjelia.legacySdk=true); shift ;;
    --ignore-certs) ignore_certs=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    *) usage >&2; exit 2 ;;
  esac
done
if [ "$ignore_certs" -eq 1 ]; then
  [ "${#legacy[@]}" -gt 0 ] || { echo "--ignore-certs is for old test phones: use it with --legacy." >&2; exit 2; }
  DEFINES+=(--dart-define=FJELIA_IGNORE_CERTS=true)
fi
command -v flutter >/dev/null || { echo "Flutter is not on PATH." >&2; exit 1; }
command -v adb >/dev/null || { echo "adb is not on PATH (brew install --cask android-platform-tools)." >&2; exit 1; }
# Homebrew upgrades remove the JDK a fixed JAVA_HOME points at.
if [ -z "${JAVA_HOME:-}" ] || [ ! -x "$JAVA_HOME/bin/java" ]; then
  JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null)" || { echo "No JDK 17 found (brew install openjdk@17)." >&2; exit 1; }
  export JAVA_HOME
fi
if [ -z "$device" ]; then
  devices=$(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')
  case "$(printf '%s\n' "$devices" | grep -c .)" in
    1) device="$devices" ;;
    0) echo "No Android device: connect one with USB debugging allowed (adb devices)." >&2; exit 2 ;;
    *) echo "Several Android devices: pass --device or set FJELIA_ANDROID_DEVICE:" >&2
       printf '  %s\n' $devices >&2; exit 2 ;;
  esac
fi
sdk=$(adb -s "$device" shell getprop ro.build.version.sdk | tr -d '\r')
if [ "${#legacy[@]}" -eq 0 ] && [ -n "$sdk" ] && [ "$sdk" -lt 26 ]; then
  echo "The phone runs API $sdk; Fjelia needs 26. Use --legacy for a test build." >&2
  exit 2
fi
if [ -z "$log_file" ]; then
  log_file=$(mktemp "${TMPDIR:-/tmp}/fjelia-android-debug.XXXXXX")
else
  # Resolve the caller's path before entering the app directory.
  case "$log_file" in /*) ;; *) log_file="$PWD/$log_file" ;; esac
  : > "$log_file"
fi
cd "$(dirname "$0")/.."
echo "Device: $device (API $sdk)"
echo "Logs: $log_file"
if [ "$prepare" -eq 1 ]; then
  flutter pub get
  flutter pub run build_runner build
fi
# Keep stdin attached for Flutter's interactive hot reload commands. pipefail
# preserves Flutter's exit status if the build, install, or connection fails.
flutter run "$mode" --no-dds -d "$device" ${legacy[@]+"${legacy[@]}"} ${DEFINES[@]+"${DEFINES[@]}"} "$@" 2>&1 | tee "$log_file"
