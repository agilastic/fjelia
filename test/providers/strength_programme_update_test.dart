import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/auth_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/plan_schedule_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/services/strength/strength_templates.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_providers/workout_providers.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:fjelia/widgets/strength_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

/// Device review: a plan made before the goal-driven programme kept "Full
/// Body Strength — Base" once a week, with two strength days set.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'user_profile_v1': jsonEncode({
        'trainingDaysPerWeek': 6,
        'restDays': [1],
        'preferredStrengthDays': [2, 5],
        'preferredSports': ['trail_running'],
        'hoursPerWeek': 10,
      }),
    });
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
  });
  tearDown(() => db.close());

  test('legacy sessions are recognised; recovery core is current', () {
    expect(isLegacyStrengthSession('strengthFull', 'base'), isTrue);
    expect(isLegacyStrengthSession('strengthLower', 'build'), isTrue);
    expect(isLegacyStrengthSession('strengthCore', 'base'), isTrue);
    expect(isLegacyStrengthSession('strengthCore', 'recovery'), isFalse);
    expect(isLegacyStrengthSession('str-trail-base-a', 'base'), isFalse);
  });

  test('an old plan is flagged and the update replans strength', () async {
    // A plan as an earlier version made it: one Full Body session a week.
    final planId = await TrainingPlanService(db, WorkoutProviders(const []))
        .generatePlan(
          athleteId: 'self',
          raceDate: DateTime.now().add(const Duration(days: 7 * 24)),
          sport: 'trail_running',
          raceDistanceM: 80000,
          raceElevationM: 4000,
          daysPerWeek: 6,
          restDays: const [1],
          strengthDays: const [2, 5],
          hoursPerWeek: 10,
          gadSports: const ['trail_running'],
        );
    final all =
        await (db.select(db.trainingSessions)..where(
              (t) => t.planId.equals(planId) & t.sport.equals('strength'),
            ))
            .get();
    for (final s in all) {
      final second = all.any(
        (o) =>
            o.weekNumber == s.weekNumber &&
            o.sessionDate.isBefore(s.sessionDate),
      );
      if (second) {
        await (db.delete(
          db.trainingSessions,
        )..where((t) => t.id.equals(s.id))).go();
      } else if (s.phase != 'recovery') {
        await (db.update(
          db.trainingSessions,
        )..where((t) => t.id.equals(s.id))).write(
          const TrainingSessionsCompanion(subType: Value('strengthFull')),
        );
      }
    }

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        garminClientProvider.overrideWithValue(FakeWorkoutGarmin()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);
    // Kept alive while the test reads it, as a screen would.
    final sub = container.listen(strengthProgrammeOutdatedProvider, (_, _) {});
    addTearDown(sub.close);

    expect(
      await container.read(strengthProgrammeOutdatedProvider.future),
      isTrue,
    );
    await container.read(updateStrengthProgrammeProvider)();

    expect(
      await container.read(strengthProgrammeOutdatedProvider.future),
      isFalse,
    );
    final today = DateTime.now();
    final upcoming =
        await (db.select(db.trainingSessions)..where(
              (t) =>
                  t.planId.equals(planId) &
                  t.sport.equals('strength') &
                  t.status.equals('planned') &
                  t.sessionDate.isBiggerOrEqualValue(
                    DateTime(today.year, today.month, today.day),
                  ),
            ))
            .get();
    expect(upcoming.where((s) => s.subType == 'strengthFull'), isEmpty);
    expect(
      upcoming.where((s) => s.subType!.startsWith('str-trail-')).length,
      greaterThan(10),
    );
    final perWeek = <int, int>{};
    for (final s in upcoming) {
      perWeek[s.weekNumber] = (perWeek[s.weekNumber] ?? 0) + 1;
    }
    expect(
      perWeek.values.where((n) => n == 2),
      isNotEmpty,
      reason: 'both strength days',
    );
  });

  test('history sources read as names', () {
    expect(strengthSourceLabel('fjelia_live'), 'Gym mode');
    expect(strengthSourceLabel('garmin_api'), 'Garmin');
    expect(strengthSourceLabel('something_new'), isNull);
  });
}
