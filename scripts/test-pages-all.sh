#!/usr/bin/env bash
# All-pages walk on every connected test phone, one after the other: the
# iPhone, the iPhone 11 and the Android phone. Phones that are not connected
# are skipped. Results: build/test-pages/<phone>/ (screenshots, walk.log).
set -uo pipefail
cd "$(dirname "$0")"
[ -f local.env ] && . ./local.env
ios_connected() {
  [ -n "$1" ] && xcrun devicectl list devices 2>/dev/null | grep "$1" | grep -q "available\|connected"
}
summary=()
run() {
  local name=$1; shift
  echo "=== $name"
  if "$@"; then summary+=("$name: all pages clean")
  else summary+=("$name: problems, see build/test-pages/ (exit $?)"); fi
}
if ios_connected "${FJELIA_IOS_DEVICE:-}"; then run iPhone ./test-pages-ios.sh
else summary+=("iPhone: not connected, skipped"); fi
if ios_connected "${FJELIA_IOS_DEVICEI11:-}"; then run "iPhone 11" ./test-pages-ios-i11.sh
else summary+=("iPhone 11: not connected, skipped"); fi
if [ -n "$(adb devices 2>/dev/null | awk 'NR > 1 && $2 == "device"')" ]; then run Android ./test-pages-android.sh
else summary+=("Android: not connected, skipped"); fi
echo
printf '%s\n' "${summary[@]}"
! printf '%s\n' "${summary[@]}" | grep -q problems
