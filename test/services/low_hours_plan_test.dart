import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('double days', () {
    test('need at least 5 h a week; the choice comes back above', () {
      const chosen = UserProfile(maxSessionsPerDay: 2, hoursPerWeek: 4);
      expect(chosen.doubleDayAllowed, isFalse);
      expect(chosen.maxSessionsPerDay, 1);
      // Kept as chosen: going back to 5 h brings the double day back.
      expect(chosen.toJson()['maxSessionsPerDay'], 2);
      final more = chosen.copyWith(hoursPerWeek: 5);
      expect(more.doubleDayAllowed, isTrue);
      expect(more.maxSessionsPerDay, 2);
      expect(
        UserProfile.fromJson(chosen.toJson())
            .copyWith(hoursPerWeek: 8)
            .maxSessionsPerDay,
        2,
      );
    });
  });

  group('one hour a week', () {
    late AppDatabase db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await WorkoutTemplateLibrary(db).seedIfEmpty();
    });
    tearDown(() => db.close());

    test('holds no more sessions than the hour fits', () async {
      await TrainingPlanService(
        db,
        garminProviders(db, FakeWorkoutGarmin()),
      ).generatePlan(
        athleteId: 'self',
        raceDate: DateTime(today.year, today.month, today.day + 12 * 7),
        sport: 'running',
        raceDistanceM: 10000,
        daysPerWeek: 5,
        restDays: const [1, 5],
        strengthDays: const [],
        hoursPerWeek: 1,
        gadSports: const ['running'],
      );
      final sessions = await (db.select(
        db.trainingSessions,
      )..where((t) => t.status.isIn(const ['planned', 'adapted']))).get();
      expect(sessions, isNotEmpty);
      final byWeek = <int, List<TrainingSession>>{};
      for (final s in sessions) {
        (byWeek[s.weekNumber] ??= []).add(s);
      }
      for (final week in byWeek.values) {
        // Two half hours or one hour, not five short sessions.
        expect(week.length, lessThanOrEqualTo(2));
        final minutes = week.fold<int>(0, (a, s) => a + s.plannedDurationMin);
        expect(minutes, lessThanOrEqualTo(60));
        for (final s in week) {
          expect(s.plannedDurationMin, greaterThanOrEqualTo(30));
        }
      }
    });
  });
}
