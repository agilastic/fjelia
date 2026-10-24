#!/usr/bin/env bash
# Build an Android release APK or app bundle.
set -euo pipefail
# Optional per-developer settings (git-ignored): FJELIA_IOS_DEVICE, FJELIA_TEAM_ID.
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
# Build-time credentials (see secrets.example.json); absent = services unavailable.
DEFINES=()
[ -f "$(dirname "$0")/../secrets.json" ] && DEFINES+=(--dart-define-from-file=secrets.json)
cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Usage: scripts/build-android.sh [--apk|--aab] [--install --device DEVICE_ID]

Default: release APK. --aab creates a Play Store app bundle.
--install requires an APK and an explicit Android device ID (flutter devices).
The current project signs releases with its development key; configure a release
keystore in android/app/build.gradle.kts before publishing to Google Play.
EOF
}
format=apk
install=0
device=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --apk) format=apk; shift ;;
    --aab) format=appbundle; shift ;;
    --install) install=1; shift ;;
    --device)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { usage >&2; exit 2; }
      device="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
if [ "$install" -eq 1 ] && { [ -z "$device" ] || [ "$format" != apk ]; }; then
  echo "--install requires --device and --apk." >&2
  exit 2
fi
command -v flutter >/dev/null
flutter pub get
flutter pub run build_runner build
flutter build "$format" --release --no-pub ${DEFINES[@]+"${DEFINES[@]}"}
if [ "$format" = apk ]; then
  echo "APK: $PWD/build/app/outputs/flutter-apk/app-release.apk"
else
  echo "Bundle: $PWD/build/app/outputs/bundle/release/app-release.aab"
fi
if [ "$install" -eq 1 ]; then flutter install --release -d "$device"; fi
