import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia_core/services/dfa_alpha1.dart';
import 'package:fjelia_core/services/ramp_test.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    await db
        .into(db.athleteThresholds)
        .insert(
          AthleteThresholdsCompanion.insert(
            athleteId: 'self',
            maxHrBpm: const Value(185),
            thresholdHrBpm: const Value(165),
            runHrZonesJson: const Value('[92,110,128,146,165]'),
          ),
        );
  });
  tearDown(() => db.close());

  TrainingPlanService service() =>
      TrainingPlanService(db, garminProviders(db, FakeWorkoutGarmin()));

  /// A run [daysAgo] with chest-strap data: a progression or a steady run.
  Future<void> strapRun(
    int daysAgo, {
    bool progression = false,
    String type = 'running',
  }) async {
    final id = '$type$daysAgo';
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: id,
            type: type,
            startDate: day(-daysAgo).add(const Duration(hours: 8)),
            durationSeconds: 3000,
          ),
        );
    final windows = [
      for (var t = 60000; t <= 49 * 60000; t += 30000)
        () {
          final m = t / 60000;
          final hr = progression
              ? (m < 10 ? 120.0 : 125 + 5 * ((m - 10) ~/ 3).toDouble())
              : 135.0;
          return DfaWindow(
            t: t,
            alpha1: progression ? (3.65 - 0.02 * hr).clamp(0.2, 1.5) : 0.45,
            heartRate: hr,
            artifacts: 0,
          );
        }(),
    ];
    await db
        .into(db.dfaAlpha1Results)
        .insert(
          DfaAlpha1ResultsCompanion.insert(
            activityId: id,
            rrCount: 6000,
            artifacts: 0.01,
            windowsJson: jsonEncode([for (final w in windows) w.toJson()]),
            computedAt: now,
          ),
        );
  }

  Future<List<TrainingSession>> generate({
    bool rampTests = true,
    String sport = 'running',
  }) async {
    await service().generatePlan(
      athleteId: 'self',
      raceDate: day(16 * 7),
      sport: sport,
      raceDistanceM: 21097,
      daysPerWeek: 5,
      restDays: const [1, 5],
      strengthDays: const [],
      hoursPerWeek: 6,
      gadSports: [sport],
      rampTests: rampTests,
    );
    return (db.select(db.trainingSessions)
          ..where((t) => t.status.isIn(const ['planned', 'adapted']))
          ..orderBy([(t) => OrderingTerm.asc(t.sessionDate)]))
        .get();
  }

  List<TrainingSession> rampsOf(List<TrainingSession> sessions) =>
      sessions.where((s) => s.subType == rampTestSubType).toList();

  test('without a chest strap there is no ramp test', () async {
    expect(rampsOf(await generate()), isEmpty);
  });

  test('with a chest strap the plan holds a ramp test about every four weeks, '
      'never in the race weeks', () async {
    await strapRun(3);
    final sessions = await generate();
    final ramps = rampsOf(sessions);
    expect(ramps.length, greaterThanOrEqualTo(2));
    for (var i = 1; i < ramps.length; i++) {
      expect(
        ramps[i].sessionDate.difference(ramps[i - 1].sessionDate).inDays,
        greaterThanOrEqualTo(25),
      );
    }
    for (final r in ramps) {
      expect(r.sessionType, 'key');
      expect(r.title, rampTestTitle);
      expect(r.sessionDate.isBefore(day(16 * 7 - 6)), isTrue);
      expect(r.plannedDurationMin, inInclusiveRange(45, 60));
    }
    // A week has one hard session for the test, not one more on top.
    final week = ramps.first.sessionDate;
    final around = sessions.where(
      (s) =>
          s.sessionType == 'key' &&
          (s.sessionDate.difference(week).inDays).abs() <= 1 &&
          s.id != ramps.first.id,
    );
    expect(around, isEmpty);
  });

  test('a progression run on their own pushes the next test back', () async {
    await strapRun(10, progression: true);
    final ramps = rampsOf(await generate());
    expect(ramps, isNotEmpty);
    expect(ramps.first.sessionDate.isBefore(day(18)), isFalse);
  });

  test('a triathlon tests running and cycling in turn', () async {
    await strapRun(3);
    await strapRun(5, type: 'cycling');
    final ramps = rampsOf(await generate(sport: 'triathlon'));
    expect(ramps.length, greaterThanOrEqualTo(2));
    expect(ramps.any((r) => r.sport == 'running'), isTrue);
    expect(ramps.any((r) => r.sport.startsWith('cycling')), isTrue);
    for (var i = 1; i < ramps.length; i++) {
      expect(
        ramps[i].sessionDate.difference(ramps[i - 1].sessionDate).inDays,
        greaterThanOrEqualTo(25),
      );
    }
  });

  test(
    'a triathlon without a chest strap on the bike tests running only',
    () async {
      await strapRun(3);
      final ramps = rampsOf(await generate(sport: 'triathlon'));
      expect(ramps, isNotEmpty);
      expect(ramps.every((r) => r.sport == 'running'), isTrue);
    },
  );

  test('the setting turns it off', () async {
    await strapRun(3);
    expect(rampsOf(await generate(rampTests: false)), isEmpty);
  });

  test('stages rise in heart rate to above LT2 and reach the watch as '
      'they are', () async {
    await strapRun(3);
    final ramp = rampsOf(await generate()).first;
    final stages = [
      for (final s in (jsonDecode(ramp.stepsJson!) as List).cast<Map>())
        if ((s['stepType'] as Map)['stepTypeKey'] == 'interval') s,
    ];
    expect(stages.length, inInclusiveRange(6, 12));
    final hrs = [for (final s in stages) (s['targetValueOne'] as num) + 2];
    for (var i = 1; i < hrs.length; i++) {
      expect(hrs[i], greaterThan(hrs[i - 1]));
    }
    // From 20 bpm below LT1 (top of zone 2: 127) to 5 above LT2 (165).
    expect(hrs.first, closeTo(107, 1));
    expect(hrs.last, closeTo(170, 1));

    final prepared = await service().prepareWorkout(ramp.id);
    final sent = [
      for (final s in prepared.steps)
        if ((s['stepType'] as Map)['stepTypeKey'] == 'interval') s,
    ];
    expect(sent.length, stages.length);
    expect(sent.first['targetValueOne'], stages.first['targetValueOne']);
    expect(sent.last['targetValueTwo'], stages.last['targetValueTwo']);
    expect(sent.any((s) => s.containsKey('fixedTarget')), isFalse);
  });

  test('power stages run from half FTP to just above it', () {
    final steps = rampTestSteps(
      lt1: 140,
      lt2: 165,
      zoneOf: (_) => 3,
      power: true,
    );
    final stages = steps.where((s) => s['ftpFraction'] != null).toList();
    expect(stages.first['ftpFraction'], 0.5);
    expect(stages.last['ftpFraction'], closeTo(1.05, 1e-9));
    expect(steps.first['zoneNumber'], 1);
    expect(steps.last['zoneNumber'], 1);
  });
}
