import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    // Six weeks of easy running: 3 × 60 min per week, all zone 2.
    final today = DateTime.now();
    var n = 0;
    for (var d = 41; d >= 1; d -= 2) {
      if (n++ % 7 >= 3) continue;
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'a$d',
              name: 'Run',
              type: 'running',
              startDate: today.subtract(Duration(days: d)),
              durationSeconds: 3600,
              distanceMeters: const Value(10000),
              hrZonesJson: Value(
                jsonEncode({
                  'zone1': 10,
                  'zone2': 88,
                  'zone3': 2,
                  'zone4': 0,
                  'zone5': 0,
                }),
              ),
              source: const Value('garmin'),
            ),
          );
    }
  });

  tearDown(() => db.close());

  test('plan respects experience, age and recent training history', () async {
    final service = TrainingPlanService(db, FakeWorkoutGarmin());
    final today = DateTime.now();
    final planId = await service.generatePlan(
      athleteId: 'self',
      raceDate: today.add(const Duration(days: 16 * 7)),
      sport: 'running',
      raceDistanceM: 21097,
      hoursPerWeek: 8,
      athlete: const PlanAthleteProfile(
        experienceLevel: 'beginner',
        sex: 'f',
        age: 55,
      ),
    );
    final sessions = await (db.select(
      db.trainingSessions,
    )..where((t) => t.planId.equals(planId))).get();
    expect(sessions, isNotEmpty);
    Iterable<TrainingSession> week(int w) =>
        sessions.where((s) => s.weekNumber == w);
    final first = sessions
        .map((s) => s.weekNumber)
        .reduce((a, b) => a < b ? a : b);

    // Volume starts near the ~3 h/week actually trained, not at 8 h.
    final firstMinutes = week(
      first,
    ).fold<int>(0, (sum, s) => sum + s.plannedDurationMin);
    expect(firstMinutes, lessThan(300));

    // Long run capped near the longest recent run (60 min).
    for (final s in week(first).where((s) => s.sessionType == 'long')) {
      expect(s.plannedDurationMin, lessThanOrEqualTo(68));
    }

    // Beginner: at most one hard session per week.
    for (final w in sessions.map((s) => s.weekNumber).toSet()) {
      expect(
        week(w).where((s) => s.sessionType == 'key' && s.sport != 'strength'),
        hasLength(lessThanOrEqualTo(1)),
      );
    }

    // Beginner aged 55: a recovery week every third week.
    expect(week(first + 2).every((s) => s.phase == 'recovery'), isTrue);

    // No thresholds: HR targets come from the age/sex max-HR estimate
    // (Gulati: 206 − 0.88 × 55 ≈ 158 bpm).
    final hr =
        jsonDecode(
              week(
                first,
              ).firstWhere((s) => s.hrRangesJson != null).hrRangesJson!,
            )
            as Map<String, dynamic>;
    expect(hr['high'] ?? hr['low'], isNotNull);
    expect((hr['high'] ?? hr['low']) as int, lessThanOrEqualTo(158));
  });

  test(
    'HR targets use stored zone floors (zone N = floor N … floor N+1)',
    () async {
      await db
          .into(db.athleteThresholds)
          .insert(
            AthleteThresholdsCompanion.insert(
              athleteId: 'self',
              runHrZonesJson: Value(jsonEncode([120, 145, 155, 163, 171])),
            ),
          );
      final service = TrainingPlanService(db, FakeWorkoutGarmin());
      final planId = await service.generatePlan(
        athleteId: 'self',
        raceDate: DateTime.now().add(const Duration(days: 10 * 7)),
        sport: 'running',
        raceDistanceM: 10000,
        hoursPerWeek: 4,
      );
      final sessions = await (db.select(
        db.trainingSessions,
      )..where((t) => t.planId.equals(planId))).get();
      final z2 = sessions
          .where((s) => s.hrRangesJson != null)
          .map((s) => jsonDecode(s.hrRangesJson!) as Map<String, dynamic>)
          .firstWhere((hr) => hr['zone'] == 2);
      expect(z2['low'], 145);
      expect(z2['high'], 155);
    },
  );

  test('volume ramps from current training; returning athletes faster', () {
    const athlete = PlanAthleteProfile();
    // 3 h now, 8 h target, never done before: +10 %/week from 3.3 h.
    final newRate = volumeRampRate(
      targetMin: 480,
      peakMin: 180,
      athlete: athlete,
    );
    expect(newRate, 0.10);
    // Did 8.5 h/week last year: +15 %/week.
    final backRate = volumeRampRate(
      targetMin: 480,
      peakMin: 510,
      athlete: athlete,
    );
    expect(backRate, 0.15);
    double week(int w, double rate) => rampedWeeklyMinutes(
      targetMin: 480,
      recentMin: 180,
      week: w,
      rate: rate,
    );
    expect(week(0, newRate), closeTo(198, 0.5));
    expect(week(4, backRate), greaterThan(week(4, newRate)));
    expect(week(20, newRate), 480);
    // No history: start at 70 % of the target.
    expect(
      rampedWeeklyMinutes(targetMin: 480, recentMin: 0, week: 0, rate: 0.1),
      336,
    );
  });

  test(
    'with enough history the data decides the level, not the answer',
    () async {
      final today = DateTime.now();
      // Fit athlete: 80 strain a day for ~4 months → high CTL.
      for (var d = 1; d <= 120; d++) {
        await db
            .into(db.dayScoreRecords)
            .insert(
              DayScoreRecordsCompanion.insert(
                date: DateTime(today.year, today.month, today.day - d),
                strainScore: const Value(80),
              ),
            );
      }
      // 3 runs a week for 10 weeks (30 sessions, 10 active weeks).
      for (var w = 0; w < 10; w++) {
        for (var k = 0; k < 3; k++) {
          await db
              .into(db.activityRecords)
              .insert(
                ActivityRecordsCompanion.insert(
                  activityId: 'fit-$w-$k',
                  name: 'Run',
                  type: 'running',
                  startDate: today.subtract(Duration(days: w * 7 + k * 2 + 1)),
                  durationSeconds: 60 * 60,
                  source: const Value('garmin'),
                ),
              );
        }
      }
      final service = TrainingPlanService(db, FakeWorkoutGarmin());
      final planId = await service.generatePlan(
        athleteId: 'self',
        raceDate: today.add(const Duration(days: 16 * 7)),
        sport: 'running',
        raceDistanceM: 21097,
        hoursPerWeek: 8,
        // The athlete calls themselves a beginner.
        athlete: const PlanAthleteProfile(experienceLevel: 'beginner'),
      );
      final sessions = await (db.select(
        db.trainingSessions,
      )..where((t) => t.planId.equals(planId))).get();
      final first = sessions
          .map((s) => s.weekNumber)
          .reduce((a, b) => a < b ? a : b);
      int keysIn(int w) => sessions
          .where(
            (s) =>
                s.weekNumber == w &&
                s.sessionType == 'key' &&
                s.sport != 'strength',
          )
          .length;
      // Advanced from data: two hard sessions in a week (a beginner gets one)
      // and a recovery week only every fourth week.
      final maxKeys = [
        for (var w = first; w < first + 12; w++) keysIn(w),
      ].reduce((a, b) => a > b ? a : b);
      expect(maxKeys, 2);
      expect(
        sessions
            .where((s) => s.weekNumber == first + 2)
            .every((s) => s.phase == 'recovery'),
        isFalse,
      );
    },
  );
}
