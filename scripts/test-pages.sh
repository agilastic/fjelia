#!/usr/bin/env bash
# Open every page of the app on an iPhone or Android phone, with screenshots.
set -euo pipefail
umask 077
# Optional per-developer settings (git-ignored): FJELIA_IOS_DEVICE, FJELIA_ANDROID_DEVICE.
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
cd "$(dirname "$0")/.."
# Build-time credentials (see secrets.example.json); absent = services unavailable.
DEFINES=()
[ -f secrets.json ] && DEFINES+=(--dart-define-from-file=secrets.json)
[ -f ../fjelia-service/secrets.json ] && DEFINES+=(--dart-define-from-file=../fjelia-service/secrets.json)

usage() {
  cat <<'EOF'
Usage: fjelia/scripts/test-pages.sh ios|android [--device ID] [--out DIR] [--legacy] [--ignore-certs] [--ce]

Installs a debug build and runs integration_test/all_pages_test.dart: the
real app with your data opens every tab, sheet, settings page and setup
page, scrolls each to the end and back, and reports the exceptions and
overflows Flutter reported on each page instead of stopping at the first.
Every page is captured (devicectl on the iPhone, adb screencap on Android)
into DIR (default: a temp dir) together with walk.log. Nothing is saved or
sent; the DEBUG tab is restored at the end. About 6 minutes; leave the phone
unlocked and untouched.

Exit status 0 when every page was clean, 1 otherwise.

Device: --device, else FJELIA_IOS_DEVICE / FJELIA_ANDROID_DEVICE (scripts/
local.env), else the only adb device. Android options as in dev-android.sh:
--legacy builds with minSdk 24 for Android 7 test phones, --ignore-certs
(with --legacy) accepts any TLS certificate. --ce (Android) walks Fjelia CE:
built on the public service stub, the private package is restored after.
EOF
}

platform="${1:-}"
case "$platform" in
  ios) device="${FJELIA_IOS_DEVICE:-}" ;;
  android) device="${FJELIA_ANDROID_DEVICE:-}" ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
shift
out=""
ce=0
legacy=()
ignore_certs=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --device|--out)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { usage >&2; exit 2; }
      if [ "$1" = --device ]; then device="$2"; else out="$2"; fi
      shift 2 ;;
    --legacy) legacy=(-P fjelia.legacySdk=true); shift ;;
    --ignore-certs) ignore_certs=1; shift ;;
    --ce) ce=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

if [ "$platform" = android ]; then
  if [ "$ignore_certs" -eq 1 ]; then
    [ "${#legacy[@]}" -gt 0 ] || { echo "--ignore-certs is for old test phones: use it with --legacy." >&2; exit 2; }
    DEFINES+=(--dart-define=FJELIA_IGNORE_CERTS=true)
  fi
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
      *) echo "Several Android devices: pass --device or set FJELIA_ANDROID_DEVICE." >&2; exit 2 ;;
    esac
  fi
  sdk=$(adb -s "$device" shell getprop ro.build.version.sdk | tr -d '\r')
  if [ "${#legacy[@]}" -eq 0 ] && [ -n "$sdk" ] && [ "$sdk" -lt 26 ]; then
    echo "The phone runs API $sdk; Fjelia needs 26. Use --legacy for a test build." >&2
    exit 2
  fi
fi
[ -n "$device" ] || { echo "No device: pass --device or set FJELIA_IOS_DEVICE." >&2; exit 2; }
if [ "$platform" = ios ]; then
  # As in dev-ios.sh: the MLX package needs the Metal toolchain and trust.
  bash scripts/ensure-metal-toolchain.sh
  python3 scripts/trust-mlx-plugin.py
  if [ -n "${FJELIA_TEAM_ID:-}" ]; then
    printf 'DEVELOPMENT_TEAM = %s\n' "$FJELIA_TEAM_ID" > ios/Flutter/Local.xcconfig
  fi
fi
if [ "$ce" -eq 1 ]; then
  [ "$platform" = android ] || { echo "--ce is for Android." >&2; exit 2; }
  # CE: only the public keys of secrets.json, nothing of the private package.
  DEFINES=(--dart-define=FJELIA_CE=true)
  [ -f secrets.json ] && DEFINES+=(--dart-define-from-file=secrets.json)
  [ "$ignore_certs" -eq 0 ] || DEFINES+=(--dart-define=FJELIA_IGNORE_CERTS=true)
  legacy+=(-P fjelia.ce=true)
  . scripts/public-service.sh
  use_public_service
fi
[ -n "$out" ] || out="$(mktemp -d -t fjelia-pages)"
mkdir -p "$out"
log="$out/walk.log"
: > "$log"

capture() {
  if [ "$platform" = ios ]; then
    xcrun devicectl device capture screenshot --device "$device" \
      --destination "$1" -q >/dev/null 2>&1
  else
    adb -s "$device" exec-out screencap -p > "$1" 2>/dev/null
  fi
}

echo "Screenshots and log: $out"
# flutter test -d does not find the VM service of a debug app on iOS 26 and
# DDS fails to start on Android; flutter run with DDS off works on both.
flutter run --debug --no-dds -d "$device" -t integration_test/all_pages_test.dart \
  ${legacy[@]+"${legacy[@]}"} ${DEFINES[@]+"${DEFINES[@]}"} >> "$log" 2>&1 < /dev/null &
run=$!
trap 'kill $run 2>/dev/null || true; [ "$ce" -eq 0 ] || restore_private_service' EXIT

result=failed
while IFS= read -r line; do
  case "$line" in
    *"ALL_PAGES done"*) result="${line##*ALL_PAGES done }"; break ;;
    *"Some tests failed"*|*"Error launching"*|*"Lost connection"*) break ;;
    *"PAGE_SHOT "*)
      name="${line##*PAGE_SHOT }"
      capture "$out/$name.png" || echo "$name: capture failed" >&2 ;;
    *"PAGE_OK "*) echo "ok    ${line##*PAGE_OK }" ;;
    *"PAGE_FAIL "*) echo "FAIL  ${line##*PAGE_FAIL }" ;;
  esac
done < <(tail -n +1 -F "$log")
sleep 3
if [ "$result" = failed ]; then
  tail -30 "$log" >&2
  echo "The walk did not finish. See $log" >&2
  exit 1
fi
echo
echo "Pages with problems: $result (details in $log)"
[ "${result%%/*}" = 0 ]
