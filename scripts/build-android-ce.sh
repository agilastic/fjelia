#!/usr/bin/env bash
# Build Fjelia CE, the Android community edition, as split release APKs.
set -euo pipefail
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
cd "$(dirname "$0")/.."

usage() {
  cat <<'EOT'
Usage: fjelia/scripts/build-android-ce.sh [--with-keys] [--install --device ID]

Builds Fjelia CE (com.aeh.fjelia.ce, "Fjelia CE", sign-in scheme fjeliace://)
against the public service stub: no Free AI / ProAI, FjeliaPro, Hilo/Aktiia,
Suunto or Renpho cloud. Users enter their Polar and weather keys under
Settings > Own keys and their AI keys under Settings > AI & more.

Output: one APK per ABI (arm64-v8a, armeabi-v7a, x86_64) in
build/app/outputs/flutter-apk/, for GitHub Releases.

By default no service key goes into the APK, so it can be handed out.
--with-keys takes POLAR_*, PIRATE_WEATHER_KEY and WEATHER_API_KEY from
secrets.json for a build that stays with you (never publish that APK).

Signing: android/key-ce.properties (git-ignored) with storeFile,
storePassword, keyAlias and keyPassword of the CE release keystore. Without
it the APK is signed with the debug key and cannot update a release install.
EOT
}

with_keys=0
install=0
device=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --with-keys) with_keys=1; shift ;;
    --install) install=1; shift ;;
    --device)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { usage >&2; exit 2; }
      device="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[ "$install" -eq 0 ] || [ -n "$device" ] || { echo "--install requires --device." >&2; exit 2; }
command -v flutter >/dev/null || { echo "Flutter is not on PATH." >&2; exit 1; }
if [ -z "${JAVA_HOME:-}" ] || [ ! -x "$JAVA_HOME/bin/java" ]; then
  JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null)" || { echo "No JDK 17 found (brew install openjdk@17)." >&2; exit 1; }
  export JAVA_HOME
fi
[ -f android/key-ce.properties ] || echo "Note: android/key-ce.properties missing, signing with the debug key." >&2

# Only the CE switch and, with --with-keys, the public service keys of
# secrets.json; never the private package's secrets or developer switches.
defines="$(mktemp "${TMPDIR:-/tmp}/fjelia-ce-defines.XXXXXX")"
python3 -I - "$with_keys" secrets.json "$defines" <<'PY'
import json, os, sys
with_keys, source, out = sys.argv[1] == "1", sys.argv[2], sys.argv[3]
keys = ("POLAR_CLIENT_ID", "POLAR_CLIENT_SECRET", "PIRATE_WEATHER_KEY", "WEATHER_API_KEY")
d = {"FJELIA_CE": True}
if with_keys and os.path.exists(source):
    s = json.load(open(source))
    d.update({k: s[k] for k in keys if s.get(k)})
json.dump(d, open(out, "w"))
PY
mv "$defines" "$defines.json"
defines="$defines.json"

. scripts/public-service.sh
use_public_service
# Without --no-pub: the build's own pub step writes GeneratedPluginRegistrant
# for release, without dev-only plugins such as integration_test.
flutter build apk --release --split-per-abi -P fjelia.ce=true \
  --dart-define-from-file="$defines"
rm -f "$defines"
out=build/app/outputs/flutter-apk
ls -1 "$out"/app-*-release.apk
if [ "$install" -eq 1 ]; then
  abi="$(adb -s "$device" shell getprop ro.product.cpu.abi | tr -d '\r')"
  adb -s "$device" install -r "$out/app-$abi-release.apk"
fi
