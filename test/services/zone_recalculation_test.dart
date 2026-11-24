import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/hr_zone_history.dart';
import 'package:fjelia/services/zone_recalculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// A 30-minute run at a steady [bpm], [daysAgo] days ago.
  Future<void> run(String id, int daysAgo, double bpm) {
    final at = DateTime.now().subtract(Duration(days: daysAgo));
    return db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: 'Run',
            type: 'running',
            startDate: at,
            durationSeconds: 1800,
            source: const Value('garmin'),
            metricsJson: Value(
              jsonEncode([
                for (var s = 0; s <= 1800; s += 5)
                  {
                    'hr': bpm,
                    't': at.add(Duration(seconds: s)).millisecondsSinceEpoch,
                  },
              ]),
            ),
          ),
        );
  }

  /// Percent of the workout in Z1–Z5.
  Future<List<double>> zones(String id) async {
    final a = await (db.select(
      db.activityRecords,
    )..where((t) => t.activityId.equals(id))).getSingle();
    final z = jsonDecode(a.hrZonesJson!) as Map<String, dynamic>;
    return [for (var i = 1; i <= 5; i++) (z['zone$i'] as num).toDouble()];
  }

  test('each workout is measured with the zones of its own day', () async {
    final history = HrZoneHistory(db);
    await history.record(
      'running',
      [100, 130, 145, 160, 170],
      method: ZoneMethod.initial,
      from: DateTime.fromMillisecondsSinceEpoch(0),
    );
    // New zones from five days ago on: 150 bpm moves from Z3 to Z4.
    await history.record(
      'running',
      [100, 120, 135, 150, 165],
      method: ZoneMethod.lt2,
      from: DateTime.now().subtract(const Duration(days: 5)),
    );
    await run('before', 10, 152);
    await run('after', 2, 152);
    await ZoneRecalculationService(db).recalculate(
      book: await history.book(),
      since: DateTime.now().subtract(const Duration(days: 400)),
    );
    expect((await zones('before'))[2], closeTo(100, 1));
    expect((await zones('after'))[3], closeTo(100, 1));
  });
}
