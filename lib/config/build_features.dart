import 'package:flutter/foundation.dart';

/// Enabled by scripts/dev-ios.sh, independently of debug/release mode.
const developerMenuEnabled = bool.fromEnvironment('FJELIA_DEVELOPER_MENU');

/// Apple Health does not exist on Android, and Health Connect is not wired up
/// there (no health permissions in the manifest): its entries stay hidden.
bool get systemHealthAvailable =>
    defaultTargetPlatform != TargetPlatform.android;

/// Set only by scripts/dev-android.sh --legacy --ignore-certs, for Android 7
/// test phones whose root store no longer trusts Let's Encrypt.
/// Accepts any TLS certificate; public-defines.sh strips it from handed-out
/// builds, and it has no effect outside Android.
const ignoreCertificatesForTesting = bool.fromEnvironment(
  'FJELIA_IGNORE_CERTS',
);
