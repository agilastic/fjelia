import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A foreground device recording keeps ownership until saving has finished.
final deviceRecordingOwnerProvider = StateProvider<String?>((ref) => null);
