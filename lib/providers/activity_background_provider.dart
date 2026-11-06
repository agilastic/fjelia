import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/activity_background.dart';

final activityBackgroundProvider = Provider((ref) {
  final service = ActivityBackground();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});
