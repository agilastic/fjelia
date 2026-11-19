#!/usr/bin/env bash
# All-pages walk on the Android phone (FJELIA_ANDROID_DEVICE or the only adb
# device). An Android 7 test phone (API < 26) gets the legacy build that
# accepts any TLS certificate, as with dev-android.sh --legacy --ignore-certs.
set -euo pipefail
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
device="${FJELIA_ANDROID_DEVICE:-$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')}"
[ -n "$device" ] || { echo "No Android device: connect one with USB debugging allowed (adb devices)." >&2; exit 2; }
legacy=()
sdk=$(adb -s "$device" shell getprop ro.build.version.sdk | tr -d '\r')
[ -n "$sdk" ] && [ "$sdk" -lt 26 ] && legacy=(--legacy --ignore-certs)
out="$(cd "$(dirname "$0")/.." && pwd)/build/test-pages/android"
rm -rf "$out"
exec "$(dirname "$0")/test-pages.sh" android --device "$device" --out "$out" ${legacy[@]+"${legacy[@]}"} "$@"
