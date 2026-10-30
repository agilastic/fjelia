#!/usr/bin/env bash
# Fjelia build script.
#   scripts/build.sh check                 verify toolchain
#   scripts/build.sh ios [options]        see scripts/build-ios.sh --help
#   scripts/build.sh android [options]    see scripts/build-android.sh --help
#   scripts/build.sh sim ["iPhone 17"]     debug run in the iOS Simulator
set -euo pipefail
cd "$(dirname "$0")/.."

FLUTTER="flutter"
DEFINES=()
[ -f secrets.json ] && DEFINES+=(--dart-define-from-file=secrets.json)
[ -f ../fjelia-service/secrets.json ] && DEFINES+=(--dart-define-from-file=../fjelia-service/secrets.json)

missing=0
need() { command -v "$1" >/dev/null 2>&1 || { echo "✗ missing: $1 — $2"; missing=1; }; }

check_common() {
  need flutter "brew install --cask flutter"
}
check_ios() {
  [ -d /Applications/Xcode.app ] || { echo "✗ missing: Xcode — install from the Mac App Store, then: sudo xcode-select -s /Applications/Xcode.app && sudo xcodebuild -runFirstLaunch"; missing=1; }
  need pod "brew install cocoapods"
}
check_android() {
  need java "brew install openjdk@17"
  if [ -z "${ANDROID_HOME:-}" ] && [ ! -d "$HOME/Library/Android/sdk" ]; then
    echo "✗ missing: Android SDK — brew install --cask android-commandlinetools, then:"
    echo "    sdkmanager 'platform-tools' 'platforms;android-35' 'build-tools;35.0.0'"
    echo "    flutter config --android-sdk \$(brew --prefix)/share/android-commandlinetools && flutter doctor --android-licenses"
    missing=1
  fi
}

prepare() {
  $FLUTTER pub get
  # Drift code generation (use Flutter's bundled Dart, not a standalone one).
  $FLUTTER pub run build_runner build
}

case "${1:-}" in
  check)
    check_common; check_ios; check_android
    [ $missing -eq 0 ] && echo "✓ toolchain complete" || exit 1 ;;
  ios)
    shift
    exec bash scripts/build-ios.sh "$@" ;;
  android)
    shift
    exec bash scripts/build-android.sh "$@" ;;
  sim)
    check_common; check_ios; [ $missing -eq 0 ] || exit 1
    if ! xcrun simctl list runtimes | grep -q '^iOS'; then
      echo "✗ missing: iOS Simulator runtime — xcodebuild -downloadPlatform iOS"; exit 1
    fi
    name="${2:-}"
    [ -n "$name" ] || name=$(xcrun simctl list devices available | grep -m1 -oE 'iPhone [^(]+' | sed 's/ *$//')
    [ -n "$name" ] || { echo "✗ no iPhone simulator — create one in Xcode > Window > Devices and Simulators"; exit 1; }
    xcrun simctl boot "$name" 2>/dev/null || true
    developer_dir=$(xcode-select -p)
    simulator_app="$developer_dir/Applications/Simulator.app"
    device_hub_app="${developer_dir%/Developer}/Applications/DeviceHub.app"
    if [ -d "$simulator_app" ]; then
      open "$simulator_app"
    elif [ -d "$device_hub_app" ]; then
      open "$device_hub_app"
    else
      open -a Simulator || echo "Simulator UI unavailable; continuing with the booted device."
    fi
    bash scripts/ensure-metal-toolchain.sh
    python3 scripts/trust-mlx-plugin.py
    prepare
    udid=$(xcrun simctl list devices booted | grep -m1 -F "$name" | grep -oE '[0-9A-F-]{36}')
    # Use the VM service directly: macOS may block dds_aot.dart.snapshot.
    # Hot reload still works; set FJELIA_ENABLE_DDS=1 for DDS/IDE integration.
    if [ "${FJELIA_ENABLE_DDS:-0}" = "1" ]; then
      $FLUTTER run ${DEFINES[@]+"${DEFINES[@]}"} -d "$udid"
    else
      $FLUTTER run --no-dds ${DEFINES[@]+"${DEFINES[@]}"} -d "$udid"
    fi ;;
  *)
    sed -n '2,6p' "$0"; exit 1 ;;
esac
