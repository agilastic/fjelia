import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/plan_session_actions.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:fjelia/utils/week.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

/// Issue #1: a moved workout must not come back on its old day.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late TrainingPlanService service;
  late PlanSessionActions actions;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime inDays(int n) => DateTime(today.year, today.month, today.day + n);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    final providers = garminProviders(db, FakeWorkoutGarmin());
    service = TrainingPlanService(db, providers);
    actions = PlanSessionActions(db, providers);
  });
  tearDown(() => db.close());

  Future<String> plan() async {
    final race = inDays(20 * 7);
    await db
        .into(db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: 'g',
            athleteId: 'self',
            name: 'Marathon',
            primarySport: 'running',
            distanceM: 42195,
            raceDate: race,
            priority: 'a',
            source: 'manual',
            createdAt: today,
          ),
        );
    return service.generatePlan(
      athleteId: 'self',
      raceGoalId: 'g',
      raceDate: race,
      sport: 'running',
      raceDistanceM: 42195,
      daysPerWeek: 5,
      restDays: const [1],
      strengthDays: const [3],
      hoursPerWeek: 8,
      maxSessionsPerDay: 1,
      gadSports: const ['running'],
    );
  }

  Future<void> replan(String id) => service.replan(
    planId: id,
    reason: 'test',
    daysPerWeek: 5,
    restDays: const [1],
    strengthDays: const [3],
    hoursPerWeek: 8,
    maxSessionsPerDay: 1,
    preferredSports: const ['running'],
  );

  Future<List<TrainingSession>> week(DateTime start) =>
      (db.select(db.trainingSessions)..where(
            (t) =>
                t.sessionDate.isBiggerOrEqualValue(start) &
                t.sessionDate.isSmallerThanValue(
                  DateTime(start.year, start.month, start.day + 7),
                ),
          ))
          .get();

  for (final (label, shift) in [
    ('within its week', 0),
    ('into the next week', 7),
  ]) {
    test('a session moved $label stays single after a replan', () async {
      final id = await plan();
      // Week after next: whole, untouched by today.
      final w2 = weekStartOf(inDays(14));
      final before = await week(w2);
      final s = before.firstWhere((x) => x.sport == 'running');
      // Within the week: a day of the same week without a session.
      final day = shift == 0
          ? [
              for (var d = 0; d < 7; d++)
                DateTime(w2.year, w2.month, w2.day + d),
            ].firstWhere(
              (d) => !before.any(
                (x) =>
                    x.sessionDate.year == d.year &&
                    x.sessionDate.month == d.month &&
                    x.sessionDate.day == d.day,
              ),
            )
          : DateTime(w2.year, w2.month, w2.day + 9);
      final w3 = DateTime(w2.year, w2.month, w2.day + 7);
      int kind(List<TrainingSession> l) => l
          .where((x) => x.sport == s.sport && x.sessionType == s.sessionType)
          .length;
      final nextBefore = kind(await week(w3));
      await actions.moveToDate(s, day);
      await replan(id);

      final all = await db.select(db.trainingSessions).get();
      expect(all.where((x) => x.id == s.id), hasLength(1));
      // Nothing of its kind takes its old place in its old week.
      final oldWeek = await week(w2);
      final kindBefore = before
          .where((x) => x.sport == s.sport && x.sessionType == s.sessionType)
          .length;
      final kindAfter = oldWeek
          .where((x) => x.sport == s.sport && x.sessionType == s.sessionType)
          .length;
      expect(
        kindAfter,
        kindBefore - shift ~/ 7,
        reason:
            'old week: ${oldWeek.map((x) => '${x.sessionDate.day}:${x.sessionType}').join(' ')}',
      );
      // And the week it went to holds no more of its kind than before.
      expect(kind(await week(w3)), lessThanOrEqualTo(nextBefore));
    });
  }
}
