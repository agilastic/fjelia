import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final start = DateTime.utc(2026, 11, 13, 17);

  ActivityRecordsCompanion row(
    String id, {
    String type = 'cycling',
    String? source,
    int seconds = 3600,
  }) => ActivityRecordsCompanion.insert(
    activityId: id,
    name: 'Ride',
    type: type,
    startDate: start,
    durationSeconds: seconds,
    source: Value(source ?? 'garmin_api'),
  );

  Future<String> type(String id) async => (await db.getActivityById(id))!.type;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a changed sport stays through every sync path', () async {
    await db.into(db.activityRecords).insert(row('g1'));
    await db.changeActivitySport('g1', 'indoor_cycling');
    expect(await type('g1'), 'indoor_cycling');

    // A sync updating the row.
    await (db.update(
      db.activityRecords,
    )..where((t) => t.activityId.equals('g1'))).write(
      const ActivityRecordsCompanion(
        type: Value('cycling'),
        distanceMeters: Value(30000),
      ),
    );
    expect(await type('g1'), 'indoor_cycling');
    expect((await db.getActivityById('g1'))!.distanceMeters, 30000);

    // A sync replacing the whole row.
    await db
        .into(db.activityRecords)
        .insert(row('g1'), mode: InsertMode.insertOrReplace);
    expect(await type('g1'), 'indoor_cycling');

    // Back to the provider's sport, which syncs may change again.
    await db.resetActivitySport('g1');
    expect(await type('g1'), 'cycling');
    expect(await db.activitySport('g1'), isNull);
    await (db.update(db.activityRecords)
          ..where((t) => t.activityId.equals('g1')))
        .write(const ActivityRecordsCompanion(type: Value('road_biking')));
    expect(await type('g1'), 'road_biking');
  });

  test(
    'a second change keeps the first original; choosing it resets',
    () async {
      await db.into(db.activityRecords).insert(row('g1'));
      await db.changeActivitySport('g1', 'indoor_cycling');
      await db.changeActivitySport('g1', 'virtual_ride');
      expect((await db.activitySport('g1'))!.originalType, 'cycling');
      expect(await type('g1'), 'virtual_ride');

      await db.changeActivitySport('g1', 'cycling');
      expect(await db.activitySport('g1'), isNull);
      expect(await type('g1'), 'cycling');
    },
  );

  test(
    'copies are matched by the provider sport and the change follows',
    () async {
      // The athlete makes an Apple Health ride a run; Garmin later sends
      // the same ride, 90 seconds off and a little longer.
      await db
          .into(db.activityRecords)
          .insert(row('hc_1', source: 'health_connect'));
      await db.changeActivitySport('hc_1', 'running');
      await db
          .into(db.activityRecords)
          .insert(
            row('g1', seconds: 3700).copyWith(
              startDate: Value(start.add(const Duration(seconds: 90))),
            ),
          );
      await db.deduplicateActivities();
      expect(await db.getActivityById('hc_1'), isNull);
      expect(await type('g1'), 'running');
      expect((await db.activitySport('g1'))!.originalType, 'cycling');
    },
  );
}
