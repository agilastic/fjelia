import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema 66 gains the athlete\'s note on activities', () async {
    final dir = await Directory.systemTemp.createTemp('fjelia-activity-note-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final old = AppDatabase(NativeDatabase(file));
    await old
        .into(old.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'a1',
            name: 'Run',
            type: 'running',
            startDate: DateTime(2026, 11, 10),
            durationSeconds: 1800,
          ),
        );
    await old.customStatement(
      'ALTER TABLE activity_records DROP COLUMN athlete_note',
    );
    await old.customStatement('PRAGMA user_version = 66');
    await old.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final row = await db.select(db.activityRecords).getSingle();
    expect(row.athleteNote, isNull);
    await (db.update(db.activityRecords)
          ..where((t) => t.activityId.equals('a1')))
        .write(const ActivityRecordsCompanion(athleteNote: Value('Tired')));
    expect(
      (await db.select(db.activityRecords).getSingle()).athleteNote,
      'Tired',
    );
  });
}
