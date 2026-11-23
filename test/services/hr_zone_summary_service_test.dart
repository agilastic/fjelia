import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/hr_zone_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HrZoneSummaryService service;
  final start = DateTime(2026, 11, 2, 7);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = HrZoneSummaryService(db);
  });
  tearDown(() => db.close());

  Future<void> setZones(List<int> running) => db
      .into(db.athleteThresholds)
      .insertOnConflictUpdate(
        AthleteThresholdsCompanion.insert(
          athleteId: 'self',
          runHrZonesJson: Value(jsonEncode(running)),
        ),
      );

  /// A run with one sample every [every] seconds at [bpm] for [minutes].
  Future<void> run(
    String id,
    DateTime at, {
    required int minutes,
    required double Function(int second) bpm,
    int every = 5,
    int? recordedMinutes,
  }) => db
      .into(db.activityRecords)
      .insert(
        ActivityRecordsCompanion.insert(
          activityId: id,
          name: 'Run',
          type: 'running',
          startDate: at,
          durationSeconds: minutes * 60,
          source: const Value('garmin'),
          metricsJson: Value(
            jsonEncode([
              for (
                var s = 0;
                s <= (recordedMinutes ?? minutes) * 60;
                s += every
              )
                {
                  'hr': bpm(s),
                  't': at.add(Duration(seconds: s)).millisecondsSinceEpoch,
                },
            ]),
          ),
        ),
      );

  test(
    'a workout is computed with the zones in force when it was done',
    () async {
      await setZones([100, 130, 145, 160, 170]);
      await run('a', start, minutes: 60, bpm: (_) => 150);
      await service.update();
      // Today the zones move: the old run keeps its zones and its Z3.
      await setZones([100, 120, 135, 150, 165]);
      await run('b', DateTime.now(), minutes: 60, bpm: (_) => 150);
      await service.update();
      final w = {for (final x in await service.workouts()) x.activityId: x};
      expect(w['a']!.zoneSeconds[2], closeTo(3600, 5));
      expect(w['b']!.zoneSeconds[3], closeTo(3600, 5));
      expect(w['a']!.definitionId, isNot(w['b']!.definitionId));
      final definitions = await db.select(db.hrZoneDefinitions).get();
      expect([for (final d in definitions) d.method], ['initial', 'settings']);
    },
  );

  test('missing heart rate is missing, never Z1', () async {
    await setZones([100, 130, 145, 160, 170]);
    // A 60-minute run whose strap only recorded the first 40 minutes.
    await run('a', start, minutes: 60, recordedMinutes: 40, bpm: (_) => 140);
    await service.update();
    final w = (await service.workouts()).single;
    expect(w.zoneSeconds[0], 0);
    expect(w.coveredSeconds, closeTo(40 * 60, 5));
    expect(w.elapsedSeconds, 3600);
    expect(
      w.zoneSeconds.fold(0.0, (a, b) => a + b),
      closeTo(w.coveredSeconds, 1e-6),
    );
  });

  test('a gap longer than 15 s counts only 15 s', () {
    final t0 = DateTime(2026, 11, 2, 7);
    final z = HrZoneSummaryService.zoneTime(
      [
        (t0, 150),
        (t0.add(const Duration(seconds: 5)), 150),
        // The strap drops out for two minutes.
        (t0.add(const Duration(seconds: 125)), 150),
        (t0.add(const Duration(seconds: 130)), 20), // no heart rate
        (t0.add(const Duration(seconds: 135)), 150),
      ],
      const [100, 130, 145, 160, 170],
      elapsedSeconds: 140,
    );
    // 5 s + 15 s (of the 120 s gap) + 5 s; the 20 bpm interval is invalid.
    expect(z.covered, 25);
    expect(z.seconds, [0, 0, 25, 0, 0]);
  });

  test('a lower bound belongs to its zone', () {
    final t0 = DateTime(2026, 11, 2, 7);
    final z = HrZoneSummaryService.zoneTime(
      [(t0, 145), (t0.add(const Duration(seconds: 10)), 145)],
      const [100, 130, 145, 160, 170],
      elapsedSeconds: 10,
    );
    expect(z.seconds[2], 10);
  });

  test('two recordings of one workout count once, the fuller one', () async {
    await setZones([100, 130, 145, 160, 170]);
    await run('watch', start, minutes: 60, bpm: (_) => 140);
    await run(
      'phone',
      start.add(const Duration(minutes: 2)),
      minutes: 55,
      recordedMinutes: 30,
      bpm: (_) => 140,
    );
    await service.update();
    expect([for (final w in await service.workouts()) w.activityId], ['watch']);
  });

  test('a deleted recording leaves its partner counted again', () async {
    await setZones([100, 130, 145, 160, 170]);
    await run('watch', start, minutes: 60, bpm: (_) => 140);
    await run(
      'phone',
      start.add(const Duration(minutes: 2)),
      minutes: 55,
      recordedMinutes: 30,
      bpm: (_) => 140,
    );
    await service.update();
    await (db.delete(
      db.activityRecords,
    )..where((t) => t.activityId.equals('watch'))).go();
    // Nothing new to compute: the duplicates are still looked at again.
    expect(await service.update(), 0);
    expect([for (final w in await service.workouts()) w.activityId], ['phone']);
  });

  test('no zones yet: nothing is guessed', () async {
    await run('a', start, minutes: 60, bpm: (_) => 140);
    expect(await service.update(), 0);
    expect(await service.workouts(), isEmpty);
  });

  test('sport families', () {
    expect(HrZoneSummaryService.sportFamily('trail_running'), 'running');
    expect(HrZoneSummaryService.sportFamily('indoor_cycling'), 'cycling');
    expect(HrZoneSummaryService.sportFamily('open_water_swimming'), 'swimming');
    expect(HrZoneSummaryService.sportFamily('indoor_rowing'), 'other');
    expect(HrZoneSummaryService.sportFamily('strength_training'), isNull);
  });
}
