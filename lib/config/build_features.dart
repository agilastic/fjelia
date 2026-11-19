import 'package:flutter/foundation.dart';

/// Hilo PDF reports are read with PDFKit, which only Apple devices have.
bool get pdfReportsAvailable => onDeviceAiAvailable;

/// Fjelia CE, the Android community edition (scripts/build-android-ce.sh):
/// built on the public service stub, without Free AI / ProAI, FjeliaPro,
/// Hilo/Aktiia, Suunto and the Renpho cloud; the user enters the Polar and
/// weather keys under Settings > Own keys.
const communityEdition = bool.fromEnvironment('FJELIA_CE');

/// Scheme of the sign-in callbacks (Polar); CE has its own, so both apps can
/// be installed side by side. Must match the Android manifest.
const authCallbackScheme = communityEdition ? 'fjeliace' : 'fjelia';

/// Enabled by scripts/dev-ios.sh, independently of debug/release mode.
const developerMenuEnabled = bool.fromEnvironment('FJELIA_DEVELOPER_MENU');

/// Apple Health does not exist on Android, and Health Connect is not wired up
/// there (no health permissions in the manifest): its entries stay hidden.
bool get systemHealthAvailable =>
    defaultTargetPlatform != TargetPlatform.android;

/// Apple Intelligence and the MLX models run only on Apple devices.
bool get onDeviceAiAvailable =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Set only by scripts/dev-android.sh --legacy --ignore-certs, for Android 7
/// test phones whose root store no longer trusts Let's Encrypt.
/// Accepts any TLS certificate; public-defines.sh strips it from handed-out
/// builds, and it has no effect outside Android.
const ignoreCertificatesForTesting = bool.fromEnvironment(
  'FJELIA_IGNORE_CERTS',
);
