# Mobile builds

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
