import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/activity_coach_context.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_coach_context_test.dart' show act;

void main() {
  final day = DateTime(2026, 11, 2, 7, 5);

  /// 60 minutes at a steady 3 m/s; heart rate rises from 140 to 150.
  String samples() => jsonEncode([
    for (var i = 0; i <= 60; i++)
      {
        't': day.add(Duration(minutes: i)).millisecondsSinceEpoch,
        'd': i * 180.0,
        'spd': 3.0,
        'hr': i < 30 ? 140 : 150,
      },
  ]);

  ActivityRecord target() => act('t', day, minutes: 60).copyWith(
    hrZonesJson: const Value('{"zone1":360,"zone2":2520,"zone3":720}'),
    metricsJson: Value(samples()),
    avgRunCadence: const Value(172),
    recoveryTimeSeconds: const Value(36 * 3600),
  );

  test('details, zones, halves and the sessions around it', () {
    final toon = ActivityCoachContextBuilder.buildFrom(target(), [
      target(),
      act('ride', day.subtract(const Duration(days: 1)), type: 'cycling'),
      act('r1', day.subtract(const Duration(days: 3))),
      act('after', day.add(const Duration(days: 2))),
      act('old', day.subtract(const Duration(days: 40))),
    ]);
    expect(toon, contains('[ActivityDetail:Start:07:05'));
    expect(toon, contains('Cadence:172'));
    expect(toon, contains('RecoveryH:36'));
    // Seconds turned into percent.
    expect(toon, contains('[HRZones%:Z1:10,Z2:70,Z3:20,Z4:0,Z5:0]'));
    // Same speed, higher heart rate: drift of +7.1 %.
    expect(toon, contains('[Halves:First:5:33/km,HR140;Second:5:33/km,HR150'));
    expect(toon, contains('HRDrift:+7.1%'));
    expect(toon, contains('[Around:14dBefore..3dAfter,N:3]'));
    expect(toon, contains('(-1),Sport:ride'));
    expect(toon, contains('(+2),Sport:run'));
    // Too old for "around", but one of the last runs before it.
    final [around, same] = toon.split('[SameSport:run:Last2Before]');
    expect(around, isNot(contains('(-40)')));
    expect(same, contains('(-40),Sport:run'));
    // Names stay out.
    expect(toon, isNot(contains('Morgenlauf')));
  });

  test(
    'the day, the planned session and DFA alpha1 from the database',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final a = target();
      await db
          .into(db.activityRecords)
          .insert(a.toCompanion(true).copyWith(id: const Value.absent()));
      await db
          .into(db.sleepRecords)
          .insert(
            SleepRecordsCompanion.insert(
              date: DateTime(2026, 11, 2),
              totalSleepSeconds: 7 * 3600 + 1800,
              deepSleepSeconds: 0,
              remSleepSeconds: 0,
              lightSleepSeconds: 0,
              awakeSleepSeconds: 0,
              sleepScore: const Value(82),
            ),
          );
      await db
          .into(db.sessionActuals)
          .insert(
            SessionActualsCompanion.insert(
              sessionId: 's1',
              activityId: const Value('t'),
              rpe: const Value(6),
              durationRatio: const Value(1.1),
            ),
          );
      await db
          .into(db.dfaAlpha1Results)
          .insert(
            DfaAlpha1ResultsCompanion.insert(
              activityId: 't',
              rrCount: 3600,
              artifacts: 1.2,
              windowsJson: '[]',
              hrvt1Bpm: const Value(141),
              hrvt2Bpm: const Value(163),
              computedAt: day,
            ),
          );
      final toon = await ActivityCoachContextBuilder(db).build(a);
      expect(toon, contains('[DayOfActivity:SleepH:7.5,SleepScore:82'));
      expect(toon, contains('[PlannedSession:DurationVsPlan:1.1x,RPE:6]'));
      expect(
        toon,
        contains(
          '[DFAalpha1:Beats:3600,Artifacts:1.2%,HRVT1:141bpm,HRVT2:163bpm',
        ),
      );
    },
  );
}
