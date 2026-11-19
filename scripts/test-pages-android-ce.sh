#!/usr/bin/env bash
# All-pages walk of Fjelia CE on the Android phone (see test-pages-android.sh).
set -euo pipefail
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
device="${FJELIA_ANDROID_DEVICE:-$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')}"
[ -n "$device" ] || { echo "No Android device: connect one with USB debugging allowed (adb devices)." >&2; exit 2; }
legacy=()
sdk=$(adb -s "$device" shell getprop ro.build.version.sdk | tr -d '\r')
[ -n "$sdk" ] && [ "$sdk" -lt 26 ] && legacy=(--legacy --ignore-certs)
out="$(cd "$(dirname "$0")/.." && pwd)/build/test-pages/android-ce"
rm -rf "$out"
exec "$(dirname "$0")/test-pages.sh" android --ce --device "$device" --out "$out" ${legacy[@]+"${legacy[@]}"} "$@"
