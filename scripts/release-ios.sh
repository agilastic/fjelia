#!/usr/bin/env bash
# Archive the iOS app, export an IPA and (by default) upload it to TestFlight.
# Visual Studio App Center was shut down on 2025-03-31, so TestFlight / App Store
# Connect is the replacement for distributing iOS test builds.
set -euo pipefail
cd "$(dirname "$0")/.."
# Optional per-developer settings (git-ignored): FJELIA_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH.
[ -f scripts/local.env ] && . scripts/local.env
DEFINES=()
[ -f secrets.json ] && DEFINES+=(--dart-define-from-file=secrets.json)

usage() {
  cat <<'EOF'
Usage: scripts/release-ios.sh [--team TEAM_ID] [--build-number N] [--no-upload]

Builds a signed release IPA into build/ios/ipa/. Unless --no-upload is given it
is uploaded to App Store Connect (TestFlight) in the same step.

Build number defaults to the git commit count (must increase on every upload).

Authentication for the upload, either:
  * an App Store Connect API key: set ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH
    (path to AuthKey_XXXX.p8) in scripts/local.env or the environment, or
  * an Apple account signed in to Xcode (Settings > Accounts).
Team: --team, FJELIA_TEAM_ID, or the project's signing team.
EOF
}
team="${FJELIA_TEAM_ID:-}"
build_number="$(git rev-list --count HEAD)"
upload=1
while [ "$#" -gt 0 ]; do
  case "$1" in
    --team|--build-number)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { usage >&2; exit 2; }
      if [ "$1" = --team ]; then team="$2"; else build_number="$2"; fi
      shift 2 ;;
    --no-upload) upload=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
command -v flutter >/dev/null
command -v xcodebuild >/dev/null

options="$(mktemp -t fjelia-export.XXXXXX)"
trap 'rm -f "$options"' EXIT
cat >"$options" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
$( [ -n "$team" ] && printf '  <key>teamID</key><string>%s</string>\n' "$team" )
</dict></plist>
EOF

flutter pub get
flutter pub run build_runner build
flutter build ipa --release --no-pub --build-number "$build_number" \
  --export-options-plist "$options" ${DEFINES[@]+"${DEFINES[@]}"}

ls build/ios/ipa/*.ipa

if [ "$upload" -eq 1 ]; then
  # Upload the archive in a second step so the IPA above is always kept locally.
  sed -i '' 's#<string>export</string>#<string>upload</string>#' "$options"
  auth=()
  if [ -n "${ASC_KEY_ID:-}" ]; then
    auth=(-authenticationKeyID "$ASC_KEY_ID"
          -authenticationKeyIssuerID "${ASC_ISSUER_ID:?set ASC_ISSUER_ID}"
          -authenticationKeyPath "${ASC_KEY_PATH:?set ASC_KEY_PATH}")
  fi
  xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive \
    -exportOptionsPlist "$options" -exportPath build/ios/upload \
    -allowProvisioningUpdates ${auth[@]+"${auth[@]}"}
  echo "Uploaded build $build_number. It appears in TestFlight after Apple's processing (~5-30 min)."
fi
