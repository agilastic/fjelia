import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/control/execution.dart';
import 'package:fjelia/services/control/stimulus.dart';
import 'package:fjelia/services/post_workout_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const easy = Stimulus(minutes: 60, z3Min: 0, z4Min: 0);
  const threshold = Stimulus(minutes: 60, z3Min: 30, z4Min: 25);

  group('intensity against the plan', () {
    test('60 min at Z4 for 60 min planned at Z2 is too hard', () {
      const done = Stimulus(minutes: 60, z3Min: 50, z4Min: 40);
      expect(intensityVerdict(easy, done), 'hard');
      expect(
        executionOutcome(durationRatio: 1, intensity: 'hard'),
        ExecutionOutcome.tooHard,
      );
    });

    test('shorter but much harder still counts as too hard', () {
      const done = Stimulus(minutes: 35, z3Min: 25, z4Min: 15);
      expect(
        executionOutcome(
          durationRatio: .58,
          intensity: intensityVerdict(easy, done),
        ),
        ExecutionOutcome.tooHard,
      );
    });

    test('a threshold session ridden easy misses its quality', () {
      const done = Stimulus(minutes: 60, z3Min: 5, z4Min: 0);
      expect(intensityVerdict(threshold, done), 'easy');
      expect(
        executionOutcome(durationRatio: 1, intensity: 'easy'),
        ExecutionOutcome.tooEasy,
      );
    });

    test('a few minutes above plan are no reason to call it hard', () {
      const done = Stimulus(minutes: 60, z3Min: 8, z4Min: 2);
      expect(intensityVerdict(easy, done), 'on');
    });

    test('without zones the intensity is unknown, never invented', () {
      const done = Stimulus(minutes: 60, z3Min: 0, z4Min: 0, zonesKnown: false);
      expect(intensityVerdict(threshold, done), isNull);
      expect(executionOutcome(durationRatio: 1), ExecutionOutcome.completed);
    });

    test('far more load at the planned length is too hard', () {
      const done = Stimulus(minutes: 60, z3Min: 5, z4Min: 0);
      expect(
        intensityVerdict(easy, done, loadRatio: 1.5, durationRatio: 1),
        'hard',
      );
    });
  });

  group('shorter sessions', () {
    test('no reason yet: partial, to be asked', () {
      expect(executionOutcome(durationRatio: .5), ExecutionOutcome.partial);
    });

    test('the answer decides fatigue or an outside reason', () {
      for (final (reason, outcome) in [
        ('fatigue', ExecutionOutcome.stoppedFatigue),
        ('pain', ExecutionOutcome.stoppedFatigue),
        ('time', ExecutionOutcome.shortenedExternal),
        ('weather', ExecutionOutcome.shortenedExternal),
        ('other', ExecutionOutcome.shortenedExternal),
      ]) {
        expect(
          executionOutcome(durationRatio: .5, shortReason: reason),
          outcome,
          reason: reason,
        );
      }
    });

    test('a red morning readiness reads as fatigue without asking', () {
      expect(
        executionOutcome(durationRatio: .5, readinessLevel: 'red'),
        ExecutionOutcome.stoppedFatigue,
      );
      expect(
        executionOutcome(durationRatio: .5, readinessLevel: 'green'),
        ExecutionOutcome.partial,
      );
    });

    test('longer at plan intensity is longer, not a failure', () {
      expect(executionOutcome(durationRatio: 1.4), ExecutionOutcome.longer);
    });
  });

  group('scored workouts', () {
    late AppDatabase db;
    late PostWorkoutScorer scorer;
    final day = DateTime(2026, 11, 9);
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      scorer = PostWorkoutScorer(db);
    });
    tearDown(() => db.close());

    Future<void> plan(String id, {int minutes = 60, int zone = 2}) => db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: id,
            planId: 'p',
            athleteId: 'self',
            sessionDate: day,
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'running',
            sessionType: 'endurance',
            phase: 'base',
            primaryZone: zone,
            title: id,
            plannedDurationMin: minutes,
            plannedTrimp: minutes,
            sessionLevel: 1,
          ),
        );

    Future<ActivityRecord> run(int minutes, Map<String, num> zones) async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'a',
              name: 'Run',
              type: 'running',
              startDate: day.add(const Duration(hours: 7)),
              durationSeconds: minutes * 60,
              hrZonesJson: Value(jsonEncode(zones)),
            ),
          );
      return db.select(db.activityRecords).getSingle();
    }

    Future<SessionActual> actual() => db.select(db.sessionActuals).getSingle();

    test('an easy run raced at threshold is stored as too hard', () async {
      await plan('easy');
      await scorer.score(
        await run(60, {'zone2': 10, 'zone3': 30, 'zone4': 60}),
      );
      final a = await actual();
      expect(a.intensityVerdict, 'hard');
      expect(a.outcome, 'tooHard');
    });

    test('a short run is partial until the athlete says why', () async {
      await plan('long', minutes: 90);
      await scorer.score(await run(40, {'zone1': 20, 'zone2': 80}));
      expect((await actual()).outcome, 'partial');

      await scorer.setShortReason('long', 'weather');

      final a = await actual();
      expect(a.shortReason, 'weather');
      expect(a.outcome, 'shortenedExternal');
    });

    test('a missed session is stored as missed', () async {
      await plan('missed');
      await scorer.closePastSessions(now: day.add(const Duration(days: 3)));
      expect((await actual()).outcome, 'missed');
    });
  });
}
