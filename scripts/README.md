# Mobile builds

Build scripts load the app's ignored `secrets.json` and, when present,
`../fjelia-service/secrets.json` from the private service checkout. Free AI
access is supplied by that private package and compiled into the app. Its
credential stays in the private checkout's ignored configuration.

All iOS build and development scripts first check that `xcrun metal --version`
works. If the Metal Toolchain is missing or no longer registered, they run
`xcodebuild -downloadComponent MetalToolchain` and verify it again before
starting Flutter. An already working toolchain triggers no download. This also
catches the case where an incremental build succeeds from cache but Xcode
refuses to launch with “Download Xcode support for Metal Toolchain?”.
If Xcode was already running while the component was missing, restart Xcode
once after installation: its UI can retain the old component state even when
`xcrun metal --version` and `xcodebuild -showComponent MetalToolchain -json`
already report a usable installation.

The iOS scripts enable MLX's `CudaBuild` plugin for the reviewed, pinned MLX
revision in the current user's Xcode plugin trust file. When running Flutter
directly, run this once on each Mac before `flutter run` or `flutter build ios`:

```bash
bash scripts/ensure-metal-toolchain.sh
python3 scripts/trust-mlx-plugin.py
```

The helper verifies the MLX URL, version and revision against `Package.resolved`,
preserves other plugin entries and refuses an unreviewed MLX version. Xcode's
plugin validation remains enabled. The equivalent manual step is to open
`ios/Runner.xcworkspace` in Xcode, build, and enable the MLX `CudaBuild` plugin
when prompted. Despite its name, this plugin does no CUDA work on macOS/iOS.

For a debug session on the physical iPhone, with live logs and hot reload:

```bash
fjelia/scripts/dev-ios.sh
fjelia/scripts/dev-ios.sh --prepare
fjelia/scripts/dev-ios.sh --device <udid-or-name> --log /tmp/fjelia-dev.log
```

Set your device once in `scripts/local.env` (`FJELIA_IOS_DEVICE=…`, `FJELIA_TEAM_ID=…`; git-ignored) or pass `--device`. Logs are also saved to a unique temporary file
whose path is printed at startup. Press `r` to hot reload, `R` to hot restart,
`q` to stop, or `d` to detach. The script starts Flutter in debug mode; enable
Developer Mode and trust the developer profile on the iPhone beforehand.

Physical iPhone debug sessions use Flutter's Xcode launch path, configured by
`flutter.config.enable-lldb-debugging: false` in `pubspec.yaml`. This avoids a
[direct LLDB launcher JIT race](https://github.com/flutter/flutter/issues/190307)
seen with iOS 26.6.2 and Xcode 27.1, where `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` stops
the app and the VM service disconnects. Hot reload and hot restart remain
available. Xcode opens for the debug session; allow Terminal/your IDE to control
Xcode if macOS requests Automation access. Release builds use the regular
device launch path. Set the project flag back to `true` when testing a newer
Flutter/Xcode fix for the direct LLDB launcher.

Verified on 2026-10-29 with Flutter 3.47.7, Xcode 27.1 and a physical iPhone 17
Pro running iOS 26.6.2: debug launch connected to the Dart VM service, and a hot
reload request completed in 214 ms. The test session was then detached.

Run from the repository root. Both scripts fetch dependencies and generate Drift
sources before building a release.

```bash
# Signed iPhone build (Xcode and an Apple Account are required).
fjelia/scripts/build-ios.sh

# Build, install and launch on a device.
fjelia/scripts/build-ios.sh --device <udid-or-name> --install

# Select a signing team explicitly, or export FJELIA_TEAM_ID.
fjelia/scripts/build-ios.sh --team <TEAM_ID> --device <udid-or-name> --install

# Build without signing.
fjelia/scripts/build-ios.sh --no-codesign

# Android APK; requires the Flutter Android toolchain.
fjelia/scripts/build-android.sh

# Android Play app bundle.
fjelia/scripts/build-android.sh --aab

# Install the APK on a device listed by flutter devices.
fjelia/scripts/build-android.sh --device DEVICE_ID --install
```

The signed iPhone app is written to `fjelia/build/ios-signed/Runner.app`.
Unsigned builds are in `fjelia/build/ios/iphoneos/Runner.app`.
Android output paths are printed after the build.

The iOS script automatically selects the sole team saved in Xcode when possible.
With multiple teams, pass `--team`. Enable Developer Mode on the iPhone and trust
your developer profile in Settings → General → VPN & Device Management when
prompted. A free Personal Team installation needs renewal after seven days.

Android release builds currently use the project's debug signing key. Configure
a production keystore before publishing an app bundle to Google Play.

The existing `build.sh ios` and `build.sh android` commands accept the same
options. `build.sh sim` continues to launch the iOS simulator.
