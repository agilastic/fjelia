import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opening the database turns blank activity JSON into NULL', () async {
    final dir = Directory.systemTemp.createTempSync('fjelia_db_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/test.sqlite');

    var db = AppDatabase(NativeDatabase(file));
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'hc_1',
            name: 'Walk',
            type: 'walking',
            startDate: DateTime(2026, 10, 22, 7),
            durationSeconds: 1200,
            gpxJson: const Value(''),
            metricsJson: const Value('  '),
            hrZonesJson: const Value('{"zone1":60}'),
          ),
        );
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final row = (await db.select(db.activityRecords).get()).single;
    expect(row.gpxJson, isNull);
    expect(row.metricsJson, isNull);
    expect(row.plannedStepsJson, isNull);
    expect(row.hrZonesJson, '{"zone1":60}');
  });
}
