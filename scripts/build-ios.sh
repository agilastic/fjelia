#!/usr/bin/env bash
# Build an iPhone release; optionally install and launch it on a specific device.
set -euo pipefail
# Optional per-developer settings (git-ignored): FJELIA_IOS_DEVICE, FJELIA_TEAM_ID.
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
# Build-time credentials (see secrets.example.json); absent = services unavailable.
DEFINES=()
[ -f "$(dirname "$0")/../secrets.json" ] && DEFINES+=(--dart-define-from-file=secrets.json)
[ -f "$(dirname "$0")/../../fjelia-service/secrets.json" ] && DEFINES+=(--dart-define-from-file=../fjelia-service/secrets.json)
cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Usage: scripts/build-ios.sh [--team TEAM_ID] [--device UDID_OR_NAME] [--install] [--no-codesign]

Default: build a signed iPhone release. --install also launches it and requires
--device. Set FJELIA_TEAM_ID instead of --team if preferred. When neither is set,
the script uses the sole team in Xcode's accounts, or the project's signing team.
--no-codesign builds an unsigned app without an Apple account.
Example: scripts/build-ios.sh --device <udid-or-name> --install
EOF
}
team="${FJELIA_TEAM_ID:-}"
device=""
install=0
unsigned=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --team|--device)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { usage >&2; exit 2; }
      if [ "$1" = --team ]; then team="$2"; else device="$2"; fi
      shift 2 ;;
    --install) install=1; shift ;;
    --no-codesign) unsigned=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
if [ "$install" -eq 1 ] && { [ -z "$device" ] || [ "$unsigned" -eq 1 ]; }; then
  echo "--install requires --device and a signed build." >&2
  exit 2
fi
command -v flutter >/dev/null
command -v xcodebuild >/dev/null
bash scripts/ensure-metal-toolchain.sh
python3 scripts/trust-mlx-plugin.py
flutter pub get
flutter pub run build_runner build
flutter build ios --release --no-pub --no-codesign ${DEFINES[@]+"${DEFINES[@]}"}
if [ "$unsigned" -eq 1 ]; then
  echo "Unsigned app: $PWD/build/ios/iphoneos/Runner.app"
  exit 0
fi

if [ -z "$team" ] && command -v python3 >/dev/null; then
  team=$(python3 - <<'PY'
import pathlib, plistlib
path = pathlib.Path.home() / 'Library/Preferences/com.apple.dt.Xcode.plist'
data = plistlib.loads(path.read_bytes()) if path.exists() else {}
teams = {t['teamID'] for group in data.get('IDEProvisioningTeamByIdentifier', {}).values()
         for t in group if t.get('teamID')}
print(next(iter(teams)) if len(teams) == 1 else '')
PY
  )
fi
xcode_args=(-workspace ios/Runner.xcworkspace -scheme Runner -configuration Release)
if [ -n "$team" ]; then xcode_args+=("DEVELOPMENT_TEAM=$team"); fi
destination='generic/platform=iOS'
if [ -n "$device" ]; then destination="platform=iOS,name=$device"; fi
if [[ "$device" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{16}$ ]]; then destination="id=$device"; fi
products="$PWD/build/ios-signed"
xcodebuild "${xcode_args[@]}" -destination "$destination" \
  "CONFIGURATION_BUILD_DIR=$products" -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration build
app="$products/Runner.app"
echo "Signed app: $app"
if [ "$install" -eq 1 ]; then
  xcrun devicectl device install app --device "$device" "$app"
  if ! xcrun devicectl device process launch --device "$device" de.ebeling-hoppe.fjelia; then
    echo "App installed, but launch failed. Check the device error above." >&2
    echo "For an untrusted developer profile: Settings > General > VPN & Device Management." >&2
    exit 1
  fi
fi
