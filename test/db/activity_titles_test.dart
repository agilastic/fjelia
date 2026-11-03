import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final start = DateTime.utc(2026, 11, 3, 17);

  ActivityRecordsCompanion row(String id, String name, {String? source}) =>
      ActivityRecordsCompanion.insert(
        activityId: id,
        name: name,
        type: 'running',
        startDate: start,
        durationSeconds: 3600,
        source: Value(source ?? 'garmin_api'),
      );

  Future<String> name(String id) async => (await db.getActivityById(id))!.name;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a renamed activity keeps its title through every sync path', () async {
    await db.into(db.activityRecords).insert(row('g1', 'Hemmingen Running'));
    await db.renameActivity('g1', 'Ostereier-Lauf');
    expect(await name('g1'), 'Ostereier-Lauf');

    // A sync updating the row.
    await (db.update(
      db.activityRecords,
    )..where((t) => t.activityId.equals('g1'))).write(
      const ActivityRecordsCompanion(
        name: Value('Hemmingen Running'),
        distanceMeters: Value(10000),
      ),
    );
    expect(await name('g1'), 'Ostereier-Lauf');
    expect((await db.getActivityById('g1'))!.distanceMeters, 10000);

    // A sync replacing the whole row.
    await db
        .into(db.activityRecords)
        .insert(
          row('g1', 'Hemmingen Running'),
          mode: InsertMode.insertOrReplace,
        );
    expect(await name('g1'), 'Ostereier-Lauf');

    // Deleted and imported again, e.g. after a restore.
    await db.deleteActivityById('g1');
    await db.into(db.activityRecords).insert(row('g1', 'Hemmingen Running'));
    expect(await name('g1'), 'Ostereier-Lauf');

    // Back to the provider's name, which syncs may change again.
    await db.resetActivityTitle('g1');
    expect(await name('g1'), 'Hemmingen Running');
    await (db.update(db.activityRecords)
          ..where((t) => t.activityId.equals('g1')))
        .write(const ActivityRecordsCompanion(name: Value('Evening Run')));
    expect(await name('g1'), 'Evening Run');
  });

  test(
    'a second rename keeps the first original; other rows are untouched',
    () async {
      await db.into(db.activityRecords).insert(row('g1', 'Provider'));
      await db.into(db.activityRecords).insert(row('g2', 'Other'));
      await db.renameActivity('g1', 'One');
      await db.renameActivity('g1', 'Two');
      expect((await db.activityTitle('g1'))!.originalName, 'Provider');
      expect(await name('g2'), 'Other');
    },
  );

  test('the title follows when an Apple Health copy goes', () async {
    await db
        .into(db.activityRecords)
        .insert(row('hc_1', 'Health', source: 'health_connect'));
    await db.renameActivity('hc_1', 'Mein Lauf');
    await db.into(db.activityRecords).insert(row('g1', 'Garmin'));
    await db.deduplicateActivities();
    expect(await db.getActivityById('hc_1'), isNull);
    expect(await name('g1'), 'Mein Lauf');
  });
}
