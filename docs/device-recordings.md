# ECG and indoor recordings

Implemented for [ECG #4](https://github.com/agilastic/fjelia/issues/4) and
[FTMS #3](https://github.com/agilastic/fjelia/issues/3). These are the core
recording and file-interchange flows. Physical-device acceptance is still
required before calling either issue complete.

## Where to find them

- **+ → Record activity → Running** starts a phone-recorded activity. Enable
  **Record ECG with Polar H10**, choose the strap and press **Start recording**
  to record the run, ECG and the strap's standard heart-rate readings together.
  No watch or treadmill connection is required. Walking, Cycling and Treadmill
  run are also available. Outdoor sports offer GPS route/distance recording;
  a standard BLE heart-rate sensor can also be used without ECG.
- **+ → ECG**, or **Health → ECG**: choose a Polar H10, start/stop a recording,
  review its waveform, import a file, export or delete a recording, and link it
  to an existing workout. Existing H10 pairing is reused.
- **+ → Heart & circulation → Record sleep** starts an overnight Polar H10
  capture with ECG (130 Hz) and three-axis accelerometer data (25 Hz) in the
  same BLE connection. The stream is stored locally and included in backups.
  It does not automatically calculate sleep stages or breathing rate. Its
  detail view can export paired ECG and ACC CSVs for local analysis and ask the
  AI coach about the ECG after the existing one-time warning. Sample timestamps
  use the H10 device clock and are not assumed to be synchronized with UTC.
  Force-quitting the app interrupts capture.
- **+ → Indoor Training**, or an eligible indoor calendar workout: pair FTMS
  equipment, optionally select a standard BLE heart-rate sensor, record,
  pause/resume, and save. Settings → Connections remembers the equipment.
- **Activity details → Share FIT activity** exports a recorded activity.
  FIT sharing is available here; finishing a recording shows its saved summary.
- **Indoor Training → Gym treadmills**, also in **Settings → Connections**,
  checks direct Bluetooth support, imports legacy Netpulse/xID history and
  reads console-summary photos on the phone. See [phone-only Matrix integration](matrix-phone-integration.md).
- **Settings → System → Data export** includes ECG metadata CSV. Full backups
  contain the original samples, imported reports and unfinished checkpoints.

## Manual activity with ECG

Choose GPS, ECG, heart rate and existing blood-pressure readings in the setup.
GPS is enabled by default for outdoor activities and disabled for Treadmill
run. Allow precise location for a useful route. Without GPS, enter the final
distance and unit before **Finish and save**, if known. Missing distance and
moving time stay unknown. ECG and standard HR share one H10 connection; HR-only
recording can use any standard BLE Heart Rate Service. Heart rate is not
derived from the waveform.

GPS observations retain their original timestamps and horizontal accuracy.
Stale fixes, fixes worse than 30 m and implausible jumps are rejected. Stationary
drift is filtered, and pauses, recovery and gaps longer than 15 seconds begin a
new segment without adding a straight-line distance across the gap. Accepted
coordinates and available altitude/speed are saved in the activity and FIT
export. No coordinates are generated when GPS is disabled or unavailable.

**Include blood pressure readings** associates existing Hilo/Aktiia/Health
measurements by their actual timestamps in the active portions of the recording.
It does not initiate a new measurement or infer BP from ECG/HR. Readings appear
on the recording screen and activity details, including after a later sync.
FIT exports contain those observations as timestamped Blood Pressure messages;
BP is not interpolated into a continuous curve or used as the live HR source.

Pause stops the activity timer and finishes the current ECG segment. Resume
starts another segment; saving links every segment to the same activity.
Discarding the activity keeps the ECG segments in ECG history, unlinked.
An ECG disconnection saves the partial signal while the activity timer keeps
running; **Restart ECG recording** starts a new segment. Missing HR expires.

Switching apps, automatic screen locking and the Power button leave recording
active. **Pause recording** stops the timer, GPS and the current ECG/HR capture;
**Resume** starts new sensor segments. **Finish and save** stops and saves.
Five-second activity checkpoints and one-second ECG batches survive interruption. The
Record activity screen offers recovery of unfinished manual activities.
Backups include those checkpoints and waveforms. The saved activity supports
FIT export, while ECG retains its separate full-resolution CSV export.

### Background execution

- iOS declares `bluetooth-central` and `location` background modes. GPS uses
  a fitness `CLLocationManager` with background updates and a visible system
  location indicator, plus a `CLBackgroundActivitySession` only while GPS is
  recording. BLE notifications continue to drive ECG storage and workout
  snapshots when UI timers are suspended. No silent audio or dummy location
  updates are used to keep a timer-only recording alive.
- Android runs a user-started health foreground service, adding location and
  connected-device types only for enabled sources. It holds a bounded, renewed
  CPU wake lock during capture, retains the Flutter engine independently of the
  UI, and provides **Pause recording** / **Finish and save** notification actions.
  Pause/stop release the wake lock and stop location updates. No sticky service
  or automatic reboot restart is enabled.
- Active duration uses native continuous time (`mach_continuous_time` on iOS,
  `SystemClock.elapsedRealtime` on Android), including screen-off time and
  excluding explicit pauses. A timer-only iOS session can be suspended while
  no sensor events need delivery; returning reconstructs its active duration.
- Force quitting, OS process termination, permission revocation, Bluetooth loss
  or a device restart can interrupt capture. Committed data stays recoverable;
  recovery is paused and requires an explicit Resume. This is distinct from
  switching apps or turning the display off.

Implementation follows [Apple background location guidance](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background),
[Core Bluetooth background delivery](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html),
[Android BLE background guidance](https://developer.android.com/develop/connectivity/bluetooth/ble/background)
and [foreground-service type requirements](https://developer.android.com/develop/background-work/services/fgs/service-types).

## ECG implementation

The existing BLE transport implements Polar PMD ECG type 0, negotiating the
H10's supported 130 Hz / 14-bit setting before starting. The stored values are
signed microvolts; original 64-bit device timestamps are preserved as decimal
strings in JSON. Sample offsets use the device clock. The phone's recording
start is approximate: the H10 clock is not assumed to be synchronized with UTC.

Small sample batches are committed every second, also from incoming BLE events
while backgrounded. A disconnect stops the recording and saves it as interrupted. After process termination,
committed batches remain available and stale recording rows are marked
interrupted. Rendering reduces only the visible window using minimum/maximum
samples; storage and CSV retain the waveform's resolution and timing gaps.

CSV import accepts an explicit time column (`time_seconds` or `time_ms`) and
voltage column (`ecg_uv` or `ecg_mv`), with increasing sample times. Files must
be UTF-8, at most 20 MB and at most one million samples. The sampling frequency
is inferred from sample spacing unless declared in an exported Fjelia header.

The exported format is:

```csv
# fjelia-ecg-v1 {"recorded_at":"2026-11-05T12:00:00Z","sample_rate_hz":130,"source":"polar_h10","device_name":"Polar H10","units":"uV"}
time_seconds,ecg_uv,device_frame_end_ns,frame_sample_index
0.000000000,-123,599616023171427290,0
0.007692308,456,599616023171427290,1
```

Sleep captures store accelerometer frames alongside ECG batches in
`ecg_sample_chunks`, tagged with `stream: acc`, and identify the capture purpose
and accelerometer sample rate in recording metadata. ECG readers filter out
those tagged rows, preserving existing ECG analysis and CSV behavior. ACC raw
frames currently support the H10's uncompressed three-axis format; compressed
or unexpected frames interrupt the capture rather than being guessed.

The final two columns preserve Polar frame identity; they are empty where no
device timestamp is available. Re-importing the same original file is
deduplicated by SHA-256. The original file is retained separately.

Garmin and Apple Watch **PDF reports** can be imported and shared in their
original format. They are not treated as raw waveforms, and no raw Garmin
Connect endpoint is assumed. There is no direct Apple Health ECG reader in
this change. Signal gaps and sample coverage describe completeness; ECG beat
detection, estimated HR/HRV and signal-quality checks are available for
waveform recordings. Rhythm or interval interpretation is only available when
the optional FjeliaPro clinical module is enabled; it is not inferred from a
report-only record. Existing HRV and recovery summaries are not overwritten.

Raw ECG stays in the app-private database, using the same OS storage protection
as Fjelia's other health data. This change does not introduce an additional
application-level database-encryption layer. A waveform is analyzed and added
to coach context only after the athlete explicitly opens the ECG coach action
and confirms the one-time warning. Report-only records can also be discussed;
on Pro builds, selectable PDF text is included for the coach to explain the
report's stated findings and distinguish them from an independent waveform
analysis. If text extraction is unavailable, the coach is told that. The first
Pro overview reply opened from an ECG detail is saved in that recording's note
field. Raw samples are not written to logs. Explicit exports and full backups
contain sensitive data.

## FTMS implementation

All six standard data characteristics are decoded independently per packet:
treadmill, indoor bike, rower, cross trainer, step climber and stair climber.
Optional fields and unavailable-value sentinels stay distinct from zero.
Split notifications are merged with per-field freshness; old values expire
after five seconds. Equipment counters begin at a session baseline, and reset
after pauses/reconnections without importing earlier machine distance or
calories. Speed-derived distance is used where distance is unavailable.

Equipment and external HR share the phone's timestamp axis. Selecting an
external sensor prevents equipment HR from silently replacing it after signal
loss. Preferred sensor identity and source choice are remembered. Watches are
supported only when they broadcast the standard BLE Heart Rate Service; this
does not provide an Apple Watch companion app.

Planned workouts reuse Fjelia's resolved targets. Time and distance steps,
expanded repeats, HR/power targets, manual step progression and optional bike
power control are supported. Open-ended steps require manual advancement.
Controls require advertised support, valid min/max/increment limits, and
explicit permission for the current session. Manual override, a disconnect,
or a machine stop revokes permission. Treadmill changes require confirmation,
fresh readings, and limits of 0.5 km/h or 1 percentage point per command.

Pausing affects the app recording; start/stop of the physical machine stays
with its own console. Backgrounding preserves recording but relinquishes
automatic equipment control. Checkpoints are written every five seconds and
on pause. After a temporary equipment disconnect, three reconnection attempts
are made while the timer continues and missing metrics remain missing.
Recovered sessions resume only through an explicit user action.

The completed session is an ordinary Fjelia activity, linked to the planned
session where applicable. A synced copy gives way to the original FTMS
recording. FIT includes records, timer events, interval laps, summaries and
device identification. Additional numerical measurements are retained as
`ftms_*` FIT developer fields; receiving applications may ignore those fields.

Automatic activity uploads are not implemented. The app offers explicit FIT
sharing rather than treating a connected account or planned-workout delivery
integration as a working activity-upload destination.

### Concept2 PM5

A Concept2 PM5 is read through Concept2's own Bluetooth Smart profile
(`CE06xxxx-43E5-11E4-916C-0800200C9A66`, from the *Concept2 PM CSAFE
Communication Definition*, rev. 0.31). This works on every PM5 firmware with
Bluetooth. Newer firmware, above V150, also offers FTMS, but Fjelia still
prefers the PM5 profile, because it carries more:

- General and additional status give elapsed time, distance, speed, stroke
  rate, pace and average pace, calories, average power and the drag factor.
- Stroke data give drive length and time, recovery time, distance per stroke,
  peak and average force (converted from pounds to newtons), work per stroke
  and the stroke count. Additional stroke data give the stroke power.
- The end-of-workout summary is kept as `c2_summary_*` values.
- Heart rate from a belt paired to the PM5 arrives as equipment heart rate.
  255 means no belt and stays absent.

The values use the FTMS keys (`pace_500m`, `cad`, `w`, `machine_strokes`,
…), so the rowing display, the stroke averages, recording and FIT export
work as for an FTMS rower. Values only the PM5 has are kept as `c2_*` and
end up in the FIT developer fields.

Further details:

- **Notification rate:** The status rate is set to 250 ms. If that fails,
  the PM5's default of 500 ms stays.
- **Multiplexed records:** A PM5 that offers only the multiplexed
  characteristic (`0x0080`) is read from it.
- **Machine type:** A BikeErg (erg type 192–207) records as a bike. A SkiErg
  (erg type 128, 143, or 225 in a multi-erg workout) uses the rowing display,
  since it also gives pace per 500 m and strokes, but saves as Nordic skiing
  (`nordic_skiing`, FIT cross-country skiing / indoor skiing). A RowErg and
  an unknown erg record as a rower. Firmware before V150 cannot name the
  erg; choosing *SkiErg* as the sport before connecting saves the session
  as Nordic skiing on any firmware. A planned Nordic session preselects it.
- **No control:** Fjelia does not control a PM5. Programming workouts over
  CSAFE is not built.

The decoder (`lib/models/concept2.dart`) is tested with records laid out as
in the specification (`test/models/concept2_test.dart`). It has not been
tested on a real PM5 yet.

### Live rowing display

The recording screen has a dedicated rowing dashboard. Tap the large figure
to switch between pace per 500 metres and strokes per minute. Power and the
chosen sensor's current heart rate have separate large fields. Duration and
distance also use large figures; duration omits zero hours. The dashboard uses
high-contrast text without coloured frames, gradients or tinted metric cards.
The live ECG stays with these readings; tap its area to open a full-screen
trace without stopping the recording.
Small screens use a more compact layout, and larger accessibility text can
scroll. Colours follow DarkFjelia and LightFjelia.

`RowingStrokeAverage` smooths pace, stroke rate and power over up to three
distinct FTMS `machine_strokes` counts. Updates and split notifications for
the same count update that stroke instead of weighting it repeatedly. The
badge shows how many observed strokes contribute to each displayed mean.
Skipped strokes and absent fields are not filled in. Without a usable stroke
counter, the display uses fresh live readings without claiming a stroke mean.
Readings expire after five seconds; pause, reconnect and counter reset start
a new window. Stored samples, workout averages and FIT exports keep their
original values. Heart rate retains its existing source and freshness rules.

Focused checks: `test/models/rowing_stroke_average_test.dart` and
`test/widgets/rowing_recording_dashboard_test.dart`. Set
`FJELIA_UI_PREVIEW_DIR` when running the widget test to render local previews
for the two main figures, light mode, a small screen, landscape and large text.

## Matrix compatibility

The reviewed reports are [TMIW #223](https://github.com/TrackMyIndoorWorkout/TrackMyIndoorWorkout/issues/223),
[TouchXL #490](https://github.com/TrackMyIndoorWorkout/TrackMyIndoorWorkout/issues/490),
and [BowFlex/Johnson misidentification #596](https://github.com/TrackMyIndoorWorkout/TrackMyIndoorWorkout/issues/596).

- Legacy Matrix treadmill packets with flags `0x1b9e`/`0x1f9e` contain 20 bytes
  while advertising a longer payload. A targeted layout reads the available
  speed, distance, incline, elevation and total calories. Missing HR, power,
  energy-rate and elapsed-time fields are not invented. The unverified final
  byte is preserved as `matrix_tail_raw`.
- Legacy Matrix bike `0x15fe`/`0x1dfe` packets have a separate 20-byte layout.
- Conforming TouchXL split notifications keep the normal decoder.
- Matrix compatibility requires device-name identification plus an exact
  legacy signature. A shared Johnson manufacturer identifier does not select
  Matrix behavior. Manufacturer-name reads are not needed to record.
- Matrix treadmill control is disabled pending verification on the actual
  console, even if it advertises control characteristics.

For the user's **T7xi and T5x**, the manufacturer's product sheets distinguish
Bluetooth availability:

| Model | Manufacturer information | Fjelia status |
| --- | --- | --- |
| [T7xi](https://images.jhtassets.com/637fd4ea33fe60fa0cd3eafb133b0d645d26cae4/original/named/T7xiTreadmill%2B59608%2B%2Beng%2Bau%2BProductSellSheet.pdf) | Bluetooth enabled; the sheet does not establish FTMS support | Recording requires the actual console to expose FTMS `0x1826` and Treadmill Data `0x2acd`. Hardware verification pending. |
| [T5x](https://images.jhtassets.com/014c7b9a2e2c3577c7dade78d530345dc17b66de/original/named/T5xTreadmill%2B57752%2B%2Besp%2Bmx%2BHojadeventadeproducto.pdf) | Bluetooth: No, for the documented standard console | Direct FTMS recording needs a compatible Bluetooth-equipped replacement/retrofit. xID imports are available for equipped/networked consoles; console-summary capture also works without a workout radio. |

Console revisions and retrofits must be checked by discovered services rather
than the treadmill's model name. Matrix's
[FTMS guide](https://matrixhomefitness.com/blogs/blog/how-to-use-bluetooth-ftms-to-enhance-your-workout)
describes its home-console implementation; it does not establish FTMS support
for an older commercial T7xi or T5x.

Both supplied Matrix applications were unpacked and decompiled:

- `Matrix+Fitness_4.0.0_APKPure.apk` is an equipment trade-in/resale application
  without a BLE/FTMS implementation; see the [first APK inspection](matrix-apk-inspection.md).
- The corrected `Matrix+Home+Fitness_1.8_APKPure.xapk` is the Netpulse Matrix
  Home account/workout app. Its manifest, all eight DEX files, assets and
  native libraries provide no local Bluetooth treadmill implementation; see
  the [Matrix Home inspection](matrix-home-apk-inspection.md). Its Matrix
  integration uses account/web-service flows and supplies no additional BLE
  pairing or telemetry protocol for these consoles.

## References and remaining verification

Protocol references: the [Polar BLE SDK documentation](https://github.com/polarofficial/polar-ble-sdk),
[Polar time system](https://github.com/polarofficial/polar-ble-sdk/blob/master/documentation/TimeSystemExplained.md),
[Bluetooth FTMS specification](https://www.bluetooth.com/specifications/specs/fitness-machine-service-1-0/),
and [Track My Indoor Workout](https://github.com/TrackMyIndoorWorkout/TrackMyIndoorWorkout)
(Apache-2.0). The packet fixtures above are factual byte sequences from the
linked reports; no native SDK or TMIW dependency is added.

Automated checks cover decoders, timing, malformed packets, Matrix quirks,
source selection, recording cancellation/interruption, migration from schema
62, old/new backup round trips, duplicates, planned-session linkage, FIT CRC
and fields, localization, small-screen layout and waveform navigation.

Verification on 2026-11-05: all 114 recording tests pass, and targeted
analysis reports no issues. The full suite passes 1,935 tests, skips one, and
has two existing failures reproduced on the original commit `37574b2`:

- `screen_views_test.dart`: LOAD lower cards and form expansion remain reachable.
- `training_plan_calibration_test.dart`: plan respects experience, age and recent training history.

The full iOS simulator app builds with the native GPS/Bluetooth background
configuration. The real Android recording service and channel compile in a
standalone native fixture; the full Android application remains blocked by the
existing WebView plugin's AGP 9 incompatibility (see the Matrix integration
guide). Native build success does not replace a physical lock-screen test;
use a profile/release build on the phone for that acceptance run.

Hardware acceptance still needs an H10 and the actual FTMS equipment: start,
stop, sustained live recording, signal loss/reconnection, app switching and
screen locking for at least 30 minutes, explicit pause/resume,
checkpoint recovery, a console comparison of speed/distance/incline, and FIT
import into the intended receiving platforms. Only enable additional Matrix
controls after verifying model, firmware, units, ranges, acknowledgments and
the console's manual override behavior.
