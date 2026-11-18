#!/usr/bin/env bash
# Drive the app on a physical iPhone for the App Review screen recording.
set -euo pipefail
umask 077
# Optional per-developer settings (git-ignored): FJELIA_IOS_DEVICE.
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
cd "$(dirname "$0")/.."
# Build-time credentials (see secrets.example.json); absent = services unavailable.
DEFINES=()
[ -f secrets.json ] && DEFINES+=(--dart-define-from-file=secrets.json)
[ -f ../fjelia-service/secrets.json ] && DEFINES+=(--dart-define-from-file=../fjelia-service/secrets.json)

usage() {
  cat <<'EOF'
Usage: fjelia/scripts/review-video.sh [--device UDID] [--without-pro]

Builds a debug build and, once you have started the iPhone's own screen
recording (Control Center > Screen Recording), installs and launches it and
runs integration_test/review_video_test.dart: in English, the Health, Plan,
Load and Coach tabs, then where FjeliaPro is offered (Plan > Pro analyses,
Load > training stats, Settings > FjeliaPro) and the FjeliaPro sheet down to
the auto-renewal text and the Terms of Use and Privacy links. About 2 minutes.
If the one-time FjeliaPro question about the morning push appears, the walk
waits until you have answered it on the iPhone.
The app language and DEBUG tab are restored at the end.

--without-pro first drops the FjeliaPro access stored on the device, so the
sheet shows the plans with prices as a reviewer sees them; a still valid
subscription comes back with "Restore purchases".

The walk shows the data in the app, so restore the review sample first
(Settings > System > Data Export > Restore from backup) if your own data
should not be in the video. Leave the iPhone untouched until the script says
the walk is done, then stop the recording; it is saved to Photos.

Device: --device, or FJELIA_IOS_DEVICE (set it in scripts/local.env). The iPhone
must be paired, unlocked and in Developer Mode. Reinstall the TestFlight build
afterwards for normal use.
EOF
}

device="${FJELIA_IOS_DEVICE:-}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --device)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { usage >&2; exit 2; }
      device="$2"; shift 2 ;;
    --without-pro) DEFINES+=(--dart-define=REVIEW_WITHOUT_PRO=true); shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[ -n "$device" ] || { echo "No device: pass --device or set FJELIA_IOS_DEVICE." >&2; exit 2; }

log="$(mktemp "${TMPDIR:-/tmp}/fjelia-review-video.XXXXXX")"
echo "Building (log: $log) ..."
flutter build ios --debug -t integration_test/review_video_test.dart \
  ${DEFINES[@]+"${DEFINES[@]}"} >> "$log" 2>&1 < /dev/null

echo
echo "On the iPhone: unlock it, go to the home screen and start Screen Recording"
if [ -t 0 ]; then
  echo "(Control Center > Screen Recording). Then press Enter here."
  read -r _
else
  # Run without a terminal (e.g. by an agent): a countdown instead of Enter.
  echo "(Control Center > Screen Recording). The app starts in ${FJELIA_VIDEO_COUNTDOWN:-30} seconds."
  sleep "${FJELIA_VIDEO_COUNTDOWN:-30}"
fi

# flutter test -d does not find the VM service of a debug app on iOS 26;
# flutter run with DDS off does (as in dev-ios.sh).
flutter run --debug --no-dds -d "$device" -t integration_test/review_video_test.dart \
  ${DEFINES[@]+"${DEFINES[@]}"} >> "$log" 2>&1 < /dev/null &
run=$!
trap 'kill $run 2>/dev/null || true' EXIT

result=failed
while IFS= read -r line; do
  case "$line" in
    *"REVIEW_VIDEO done"*) result=done; break ;;
    *"Some tests failed"*|*"Error launching"*|*"Lost connection"*) break ;;
  esac
done < <(tail -n +1 -F "$log")
sleep 3
if [ "$result" != done ] || grep -q "EXCEPTION CAUGHT" "$log"; then
  grep -m1 -A14 "EXCEPTION CAUGHT" "$log" >&2 || tail -20 "$log" >&2
  echo "The walk did not finish; record again. See $log" >&2
  exit 1
fi
echo "Walk done: stop the screen recording. The video is in Photos; AirDrop it to"
echo "the Mac and attach it in App Store Connect > App Review Information."
