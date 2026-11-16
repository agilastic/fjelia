#!/usr/bin/env bash
# Take the App Store screenshots on a physical iPhone, in every app language,
# and file them under ios/screenshots/<store locale>/ for fastlane deliver.
set -euo pipefail
umask 077
# Optional per-developer settings (git-ignored): FJELIA_IOS_DEVICE, FJELIA_APPLE_ID.
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
cd "$(dirname "$0")/.."
# Build-time credentials (see secrets.example.json); absent = services unavailable.
DEFINES=()
[ -f secrets.json ] && DEFINES+=(--dart-define-from-file=secrets.json)
[ -f ../fjelia-service/secrets.json ] && DEFINES+=(--dart-define-from-file=../fjelia-service/secrets.json)

usage() {
  cat <<'EOF'
Usage: fjelia/scripts/store-screenshots.sh [--device UDID] [--langs en,de] [--keep DIR] [--upload]
       fjelia/scripts/store-screenshots.sh --upload-only

Installs a debug build on the iPhone and runs
integration_test/store_screens_test.dart: the real app with your data walks
through the store screens once per app language and prints
`STORE_SHOT <language> <screen>`; this script then takes the screenshot with
`xcrun devicectl device capture screenshot` (1206 x 2622 on an iPhone 17 Pro).

The walk hides the DEBUG tab, writes the briefing anew in each language and
restores the app language and DEBUG tab at the end. Leave the iPhone
unlocked and untouched; a full run of 13 languages takes about 25 minutes.

The pictures are filed under ios/screenshots/<store locale>/ (old iPhone
screenshots there are replaced, iPad ones kept). --upload then sends them to
App Store Connect with fastlane deliver, replacing ALL screenshots of the
version being prepared; --upload-only uploads what is in ios/screenshots/
without taking new pictures. The Apple ID comes from FJELIA_APPLE_ID or
fastlane's saved session. --keep keeps the raw captures (default: a temp dir).

Device: --device, or FJELIA_IOS_DEVICE (set it in scripts/local.env). The iPhone
must be paired, unlocked and in Developer Mode. Reinstall the TestFlight build
afterwards for normal use.
EOF
}

device="${FJELIA_IOS_DEVICE:-}"
langs=""
raw=""
upload=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --device|--langs|--keep)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { usage >&2; exit 2; }
      case "$1" in --device) device="$2" ;; --langs) langs="$2" ;; --keep) raw="$2" ;; esac
      shift 2 ;;
    --upload) upload=1; shift ;;
    --upload-only) upload=2; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
upload_screenshots() {
  # deliver reads ios/Deliverfile, so it runs from ios/.
  (cd ios && fastlane deliver --screenshots_path ./screenshots --metadata_path ./metadata \
    --app_identifier de.ebeling-hoppe.fjelia ${FJELIA_APPLE_ID:+--username "$FJELIA_APPLE_ID"} \
    --skip_metadata true --skip_binary_upload true --overwrite_screenshots true --force true \
    --run_precheck_before_submit false --submit_for_review false)
}
if [ "$upload" = 2 ]; then upload_screenshots; exit; fi

[ -n "$device" ] || { echo "No device: pass --device or set FJELIA_IOS_DEVICE." >&2; exit 2; }
[ -n "$raw" ] || raw="$(mktemp -d -t fjelia-store-shots)"
mkdir -p "$raw"
log="$raw/walk.log"
: > "$log"
[ -n "$langs" ] && DEFINES+=(--dart-define=STORE_LANGS="$langs")

echo "Raw captures and log: $raw"
# flutter test -d does not find the VM service of a debug app on iOS 26;
# flutter run with DDS off does (as in dev-ios.sh).
flutter run --debug --no-dds -d "$device" -t integration_test/store_screens_test.dart \
  ${DEFINES[@]+"${DEFINES[@]}"} >> "$log" 2>&1 < /dev/null &
run=$!
trap 'kill $run 2>/dev/null || true' EXIT

result=failed
while IFS= read -r line; do
  case "$line" in
    *"STORE_SHOT done"*) result=done; break ;;
    *"Some tests failed"*|*"Error launching"*|*"Lost connection"*) break ;;
    *STORE_SHOT*)
      set -- ${line##*STORE_SHOT }
      mkdir -p "$raw/$1"
      if xcrun devicectl device capture screenshot --device "$device" \
          --destination "$raw/$1/$2.png" -q >/dev/null 2>&1; then
        echo "$1 $2"
      else
        echo "$1 $2: capture failed" >&2
      fi ;;
  esac
done < <(tail -n +1 -F "$log")
sleep 3
if [ "$result" != done ] || grep -q "EXCEPTION CAUGHT" "$log"; then
  grep -m1 -A14 "EXCEPTION CAUGHT" "$log" >&2 || tail -20 "$log" >&2
  echo "The walk did not finish; nothing was filed. See $log" >&2
  exit 1
fi

# The order in the store, and which app language each store locale shows.
# Store locales without an app translation get the English pictures. The week
# review's AI text and pictures are in the athlete's language, so only the
# German set shows it.
python3 - "$raw" <<'EOF'
import glob, os, shutil, sys
raw, root = sys.argv[1], 'ios/screenshots'
order = ['status', 'plan-list', 'plan-month', 'plan-week', 'load-form', 'bp',
         'thresholds', 'devices', 'ai-coach']
german = order[:2] + ['week-review'] + order[2:]
store = {'en': ['en-GB', 'en-US', 'cs', 'el', 'ro', 'sv'], 'de': ['de-DE'],
         'fr': ['fr-FR'], 'it': ['it'], 'es': ['es-ES', 'es-MX'], 'ca': ['ca'],
         'nb': ['no'], 'sk': ['sk'], 'fi': ['fi'], 'da': ['da'], 'nl': ['nl-NL'],
         'pl': ['pl'], 'pt': ['pt-BR', 'pt-PT']}
for lang, locales in store.items():
    names = german if lang == 'de' else order
    shots = [f'{raw}/{lang}/{n}.png' for n in names]
    missing = [s for s in shots if not os.path.exists(s)]
    if missing:
        print(f'{lang}: skipped, missing {", ".join(map(os.path.basename, missing))}')
        continue
    for locale in locales:
        folder = f'{root}/{locale}'
        os.makedirs(folder, exist_ok=True)
        for old in glob.glob(f'{folder}/*IPHONE*.png') + glob.glob(f'{folder}/[0-9][0-9]_*.png'):
            os.remove(old)
        for i, (name, shot) in enumerate(zip(names, shots)):
            shutil.copy(shot, f'{folder}/{i:02d}_{name}.png')
        print(f'{locale}: {len(shots)} screenshots')
EOF

if [ "$upload" = 1 ]; then
  upload_screenshots
else
  echo "Filed under ios/screenshots/. Check them, then: fjelia/scripts/store-screenshots.sh --upload-only"
fi
