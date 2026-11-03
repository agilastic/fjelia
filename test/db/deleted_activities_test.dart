import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final start = DateTime(2026, 11, 2, 7);

  ActivityRecordsCompanion run(
    String id, {
    String source = 'garmin_api',
    DateTime? at,
  }) => ActivityRecordsCompanion.insert(
    activityId: id,
    name: 'Morning Run',
    type: 'running',
    startDate: at ?? start,
    durationSeconds: 3600,
    distanceMeters: const Value(10000),
    avgHeartRate: const Value(142),
    trainingLoad: const Value(88),
    gpxJson: const Value('[{"lat":52.3,"lng":9.7}]'),
    metricsJson: const Value('[{"t":0,"hr":140}]'),
    source: Value(source),
  );

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a deleted activity cannot be inserted again, by any path', () async {
    await db.into(db.activityRecords).insert(run('g1'));
    await db.deleteActivityByUser('g1');
    expect(await db.getActivityById('g1'), isNull);

    final tomb = (await db.getDeletedActivities()).single;
    expect(tomb.source, 'garmin_api');
    expect(tomb.durationSeconds, 3600);
    // Route and curves are not kept.
    expect(tomb.summaryJson, isNot(contains('lat')));
    expect(tomb.summaryJson, contains('"trainingLoad":88'));

    await db.into(db.activityRecords).insert(run('g1'));
    await db
        .into(db.activityRecords)
        .insert(run('g1'), mode: InsertMode.insertOrReplace);
    await db
        .into(db.activityRecords)
        .insert(run('g1'), mode: InsertMode.insertOrIgnore);
    expect(await db.getActivityById('g1'), isNull);
    // Other activities are not affected.
    await db.into(db.activityRecords).insert(run('g2'));
    expect(await db.getActivityById('g2'), isNotNull);
  });

  test('restore brings the summary back and lifts the block', () async {
    await db.into(db.activityRecords).insert(run('g1'));
    await db.deleteActivityByUser('g1');
    final back = (await db.restoreDeletedActivity('g1'))!;
    expect(back.name, 'Morning Run');
    expect(back.trainingLoad, 88);
    expect(back.avgHeartRate, 142);
    expect(back.gpxJson, isNull);
    expect(back.metricsJson, isNull);
    expect(await db.getDeletedActivities(), isEmpty);
    // The source may now send it in full again.
    await (db.update(db.activityRecords)
          ..where((t) => t.activityId.equals('g1')))
        .write(const ActivityRecordsCompanion(metricsJson: Value('[1]')));
    expect((await db.getActivityById('g1'))!.metricsJson, '[1]');
    expect(await db.restoreDeletedActivity('g1'), isNull);
  });

  test('an Apple Health copy of a deleted workout goes, another platform '
      'stays', () async {
    await db.into(db.activityRecords).insert(run('g1'));
    await db.deleteActivityByUser('g1');
    await db
        .into(db.activityRecords)
        .insert(
          run(
            'hc_1',
            source: 'health_connect',
            at: start.add(const Duration(seconds: 30)),
          ),
        );
    await db
        .into(db.activityRecords)
        .insert(
          run(
            'polar_1',
            source: 'polar',
            at: start.add(const Duration(seconds: 20)),
          ),
        );
    await db.deduplicateActivities();
    expect(await db.getActivityById('hc_1'), isNull);
    expect(await db.getActivityById('polar_1'), isNotNull);
  });
}
