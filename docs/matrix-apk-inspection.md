# Matrix Fitness 4.0.0 APK inspection

Inspected on 2026-11-05 to look for connection details for the user's Matrix
T7xi and T5x treadmills.

The supplied APK is a Cordova application for trading in and selling used
commercial gym equipment. It contains no treadmill Bluetooth connection
implementation that can be used for Fjelia's integration.

The user subsequently supplied the Matrix Home Fitness 1.8 bundle. Its
separate [inspection report](matrix-home-apk-inspection.md) documents the
corrected application's account/web-service integration and Bluetooth checks.

## Input and output

| Item | Value |
| --- | --- |
| Original APK | `/Users/alex/Downloads/Matrix+Fitness_4.0.0_APKPure.apk` |
| Package | `com.MatrixFitness.app` |
| Version | `4.0.0`, version code `40000` |
| SHA-256 | `6eb62d905ccd054266e382182c1d1800b5b863eacf27853af7af74e1996cc394` |
| Decompiled files | `/private/tmp/fjelia-matrix-apk-work/decompiled/` |
| Structured inspection | `/private/tmp/fjelia-matrix-apk-work/inspection.json` |
| Decompiler | JADX 1.5.6 |

The original APK was read without installation or modification. Decompiled
source and resources are retained in the temporary working directory.

## Evidence

- `resources/AndroidManifest.xml` declares Internet, storage, audio/video and
  phone-state permissions. There are no Bluetooth permissions.
- `resources/assets/www/config.xml` identifies the application as an
  equipment trade-in/resale service connecting gym operators with UK traders.
- Cordova plugins cover camera, image selection, files, media, dialogs and
  keyboard handling. No Bluetooth plugin is registered.
- The `Matrix` Android activity extends `CordovaActivity` and loads the web
  application. It contains no device connection logic.
- A direct examination of all 14,409 strings and all type/method references
  in `classes.dex` found no Android Bluetooth types or methods, BLE connection
  APIs, FTMS UUIDs, CSAFE, FitLinxx, or T7xi/T5x protocol references.
- The sole Bluetooth-named DEX string, `STREAM_BLUETOOTH_SCO`, belongs to the
  Android support media library's audio constants. It is unrelated to treadmill
  communication.
- The APK contains no native `.so` libraries. The extracted web assets also
  contain no Bluetooth or FTMS integration references.

JADX completed successfully with warnings about reconstructing some generic
Cordova file/media exception handlers. The DEX reference checks operate on
the binary tables directly, independently of the reconstructed Java methods.

## Consequence for the integration

This APK provides no additional BLE discovery rules, service/characteristic
UUIDs, pairing handshake, or telemetry decoder. The result does not establish
whether either physical treadmill has FTMS; that depends on its actual
console hardware, firmware and discovered Bluetooth services.

Further reverse engineering needs the APK of the application actually used
to pair with the treadmill, or a GATT discovery/notification capture from that
console. Existing Matrix packet handling and the hardware-validation limits
are described in [device recordings](device-recordings.md).
