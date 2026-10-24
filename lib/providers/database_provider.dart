import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/source_priority_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  ref.keepAlive();
  final db = AppDatabase(
    driftDatabase(name: 'fjelia_db'),
    metricPriorityReader: priorityForGroup,
  );
  ref.onDispose(db.close);
  return db;
});
