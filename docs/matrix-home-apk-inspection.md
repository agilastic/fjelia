# Matrix Home Fitness 1.8 bundle inspection

Inspected on 2026-11-05 for connection details relevant to the user's Matrix
T7xi and T5x treadmills. This is the corrected application supplied after the
[Matrix Fitness 4.0.0 inspection](matrix-apk-inspection.md).

The supplied Matrix Home build is a Netpulse account and workout application.
Its local code does not implement a Bluetooth treadmill connection. It provides
no pairing handshake or telemetry protocol to add to Fjelia.

## Input and output

| Item | Value |
| --- | --- |
| Original bundle | `/Users/alex/Downloads/Matrix+Home+Fitness_1.8_APKPure.xapk` |
| Package | `com.netpulse.mobile.matrixhomefitness` |
| Version | `1.8`, version code `122` |
| Bundle SHA-256 | `32e111b76f94e350ac6aadaf27b415db19ad89019c1dce020fa83f79c589b8e4` |
| Base APK | `com.netpulse.mobile.matrixhomefitness.apk` |
| Splits | `config.arm64_v8a.apk`, `config.en.apk`, `config.mdpi.apk` |
| Decompiled files | `/private/tmp/fjelia-matrix-home-apk-work/decompiled/` |
| Structured inspection | `/private/tmp/fjelia-matrix-home-apk-work/inspection.json` |
| Decompiler | JADX 1.5.6 |

The file is an XAPK bundle, despite the initially supplied `.apk` extension.
It was unpacked and inspected locally without installing it or contacting its
services. The original bundle was not modified. Extracted application code
remains in the temporary working directory.

JADX recovered the manifest, resources and 29,663 of 29,665 top-level source
units. Some methods have reconstruction errors; the run was stopped after
progress stalled on the remaining units. The connection findings also use
the complete binary DEX tables and raw asset/native-library checks, so they
do not rely on every method being decompiled successfully.

## Bluetooth checks

- The decoded `resources/AndroidManifest.xml` declares no `BLUETOOTH`,
  `BLUETOOTH_ADMIN`, `BLUETOOTH_SCAN` or `BLUETOOTH_CONNECT` permission.
- Direct inspection of all eight DEX files covers 428,873 string-table entries
  and 72,717 class definitions. There are no `android.bluetooth` type or method
  references, including `BluetoothAdapter`, `BluetoothGatt`, `BluetoothSocket`
  and `connectGatt`. These binary-table checks do not depend on successful
  Java reconstruction.
- The app's `com.netpulse` sources contain no Bluetooth, FTMS or CSAFE
  implementation. The extracted assets and nine ARM64 native libraries contain
  none of the checked Bluetooth API, FTMS UUID or CSAFE markers.
- Bluetooth-named strings in bundled libraries refer to media/audio routes,
  device parameters for Stripe 3DS, and generated resources. They do not form
  an equipment connection implementation.

## What the Matrix integration actually does

The relevant paths below are relative to the decompiler's `sources/` directory:

- `com/netpulse/mobile/matrix_workouts/MatrixWorkoutsWebViewFragment.java`:
  `getLoadUrl()` opens a configured web page with the account's `uuid` and
  `club_uuid` query parameters.
- `com/netpulse/mobile/core/api/ExerciserClient.java`:
  `getPartnerClientAccessToken()` performs an authenticated HTTP request to
  `/np/exerciser/%s/externalAccount/matrixPortal/token`.
- `com/netpulse/mobile/connected_apps/list/presenters/ConnectedAppsPresenter.java`:
  `onXidSettingsSelected()` opens account settings using profile information.
- `com/netpulse/mobile/record_workout/client/EgymApi.java` exposes account
  linking, registration, consent and login operations.
- `com/netpulse/mobile/workouts/client/WorkoutClient.java` reads and writes
  workout history through authenticated HTTP calls to
  `/np/exerciser/%s/workouts` and `/np/exerciser/%s/workout`.

These are account/web-service flows. The supplied build provides no BLE
discovery filter, service/characteristic UUID, notification subscription,
pairing sequence, or raw machine-data decoder that Fjelia could use.

## Consequence for Fjelia

No executable connection code was changed on the basis of this inspection.
The existing standard FTMS support and targeted Matrix packet handling remain
as described in [device recordings](device-recordings.md#matrix-compatibility).

The absence of a local BLE implementation in this application does not prove
whether either physical treadmill supports FTMS. Establishing that requires
the actual console's GATT service list and, where available, notification
captures. Check for Fitness Machine Service `0x1826` and Treadmill Data
`0x2acd`; a different advertised service needs its own verified protocol.
Model names and account connectivity alone cannot establish that support.
