import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/source_priority_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  ref.keepAlive();
  final db = openAppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// The app database. The background workout check opens it from its own
/// engine too, so a writer waits for the other instead of failing.
AppDatabase openAppDatabase() => AppDatabase(
  driftDatabase(
    name: 'fjelia_db',
    native: const DriftNativeOptions(setup: _waitForLocks),
  ),
  metricPriorityReader: priorityForGroup,
);

void _waitForLocks(dynamic db) => db.execute('PRAGMA busy_timeout = 5000;');
