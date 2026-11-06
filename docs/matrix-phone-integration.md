# Gym treadmills without an Apple Watch

Open **+ → Indoor Training → Gym treadmills**, or **Settings → Connections →
Gym treadmills**. These flows read equipment/account data directly into Fjelia;
Apple Health, an Apple Watch and the Matrix app are not prerequisites.

## Direct recording

**Find gym equipment** scans without a service filter. This also finds BLE
consoles that do not advertise their workout service. Selecting one opens a
temporary connection and inventories its GATT services, then disconnects.
No characteristics are read or written during this check. The report can be
shared explicitly as JSON from the connection report panel.

Supported live paths are Fitness Machine Service `0x1826` with one of the six
supported FTMS measurements, or Running Speed and Cadence Service `0x1814`
with Measurement `0x2a53`. Notify and indicate properties are both recognized.
**Use this machine** connects it to the existing indoor recorder. Choose a
separate standard BLE heart-rate sensor there if desired, then start recording.

RSC provides speed/cadence and optional stride length/distance. It provides no
incline, calories or equipment control. Its samples use the same freshness,
pause, reconnection, checkpoints and FIT-export path as the indoor recorder;
the checkpoint identifies the data protocol as `rsc`. Older checkpoints default
to `ftms`.

The targeted legacy Matrix packet decoding remains in use. Matrix treadmill
remote control remains disabled. Neither a Bluetooth icon nor a treadmill model
name establishes a supported live service. A standard T5x without a workout
radio needs one of the summary paths below.

## Matrix xID history

The xID screen supports gyms using a legacy Netpulse/xID workout portal. Ask
the gym for its HTTPS `*.netpulse.com` portal and enable workout tracking on the
console. Sign in on the console before the workout. In Fjelia, enter the portal,
xID and passcode. The saved session is held in secure storage; the passcode is
not retained. Disconnect removes that session, and expiry requires sign-in.

Load 7, 30, 90 or 365 days, review/select workouts and import them. The automatic
sync switch imports the latest seven days with normal app sync; switch it off
to use explicit imports only. Requests are read-only after sign-in, restrict
history to individual treadmill workouts and use seven-day date windows.
Redirects are not followed, and credentials/cookies are limited to validated
HTTPS Netpulse origins. Raw HTTP errors, responses and credentials are not
shown or logged.

Original interoperability code uses the formats found in the supplied Matrix
Home build: form `POST /np/login`, the `JSESSIONID` session and
`GET /np/exerciser/{uuid}/workouts`. `startDateUtc` is milliseconds,
`totalDuration` is seconds, and the explicit distance unit determines the SI
conversion. Unknown units, aggregates and malformed rows are skipped and
counted. Imported identities are scoped to the portal and account.

EGYM-only/migrated SSO accounts are not implemented by this legacy connector.
Live account acceptance still needs testing against the user's actual gym
portal. A successful fixture test is not proof that a particular facility
continues to expose the legacy endpoint. The [APK inspection](matrix-home-apk-inspection.md)
records the source of these protocol findings.

## Console summary photos and manual entry

Choose **Treadmill summary** to take/select a photo of the final console screen,
or enter the values manually. Apple Vision on iOS and the bundled ML Kit Latin
text model on Android recognize the image on the phone. There is no image
upload or dependency on EGYM xCapture. Readable labels and their positions are
used to extract duration, distance, units, calories and heart rate. Pace,
remaining time and calorie rate are excluded. Ambiguous values stay empty.

Review the workout start, duration, distance unit and all values before saving.
Only the summary fields are stored. Photos are not added to Fjelia's media
library or backups. xID and photo/manual summaries do not manufacture a speed
trace, incline trace or heart-rate zone distribution. They appear as ordinary
activities and are included in the existing backup/export flows.

Repeat imports and copies of existing workouts are skipped, including matches
across midnight. Deleted workouts are not resurrected by a later summary.
If a fuller recording arrives later, normal activity deduplication retains it
and preserves the existing activity-link migration behavior.

## References

- [Matrix xID guide](https://matrixhomefitness.com/pages/matrix-xid/parse-event)
- [Matrix 2016 5x console comparison](https://content.johnsonfit.com/inc/uploaded_media/ff93ade8af3a60373906176ce7a0fc74/engineering_menus/9b3ceba96174cdc5d05a31e3a514c00a.pdf)
- [Bluetooth FTMS specification](https://www.bluetooth.com/specifications/specs/fitness-machine-service-1-0/)
- [Bluetooth RSC specification](https://www.bluetooth.com/specifications/specs/running-speed-and-cadence-service-1-0/)
- [Apple Vision text recognition](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)
- [Android ML Kit text recognition](https://developers.google.com/ml-kit/vision/text-recognition/v2/android)

Physical acceptance still requires the gym console: discovery, sustained
recording, a comparison with its displayed values, disconnect/reconnect and
FIT import. Use the built-in connection report to establish what the user's
T7Xi or T5x actually exposes before adding any proprietary protocol or hardware
adapter support.

## Build validation

The complete iOS simulator app builds successfully. The Android photo reader
and native foreground recording/GPS service also compile into a standalone
Android fixture using the actual `MainActivity.kt`, `ActivityRecordingService.kt`,
recording manifest permissions and ML Kit dependency. The complete
Android application currently fails before compiling app code because the
existing `flutter_inappwebview_android` 1.1.3 plugin requests
`proguard-android.txt`, rejected by the repository's Android Gradle Plugin 9.1.
No unrelated dependency downgrade or pub-cache modification is included.
