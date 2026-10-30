import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/bio_age_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Profile extends UserProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile(birthYear: 1980);
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late DateTime today;

  setUp(() async {
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        userProfileProvider.overrideWith(_Profile.new),
      ],
    );
    await container.read(userProfileProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> save(int daysAgo, {int? steps, double? minutes}) =>
      db.upsertWellness(
        WellnessRecordsCompanion(
          date: Value(DateTime(today.year, today.month, today.day - daysAgo)),
          steps: Value(steps),
          intensityMinutes: Value(minutes),
          source: const Value('garmin_api'),
        ),
      );

  test(
    'daily database inputs use the step fallback only on missing-minute dates',
    () async {
      for (var i = 0; i < 7; i++) {
        await save(i, steps: 6000, minutes: i == 0 ? 72 : null);
      }
      // A prior week's many steps must not leak into this week.
      await save(20, steps: 100000, minutes: 1000);
      final r = (await container.read(bioAgeProvider.future))!;
      expect(r.activity.reportedMinutes, 72);
      expect(r.activity.estimatedWalkingMinutes, 360);
      expect(r.activity.coveredDays, 7);
      expect(r.activity.minutesForScore, 432);
      expect(r.contributions, contains('activity'));
      // Derived walking time is presentation/model data, not stored observation.
      final rows = await db.getWellnessRange(7);
      expect(rows.where((row) => row.intensityMinutes == null), hasLength(6));
    },
  );

  test(
    'missing intensity fields on otherwise present records are not zeroes',
    () async {
      for (var i = 0; i < 7; i++) {
        await save(i, steps: 10000);
      }
      final r = (await container.read(bioAgeProvider.future))!;
      expect(r.activity.reportedDays, 0);
      expect(r.activity.stepEstimatedDays, 7);
      expect(r.activity.minutesForScore, 700);
    },
  );

  test(
    'incomplete imports omit the factor until the missing day arrives',
    () async {
      for (var i = 0; i < 6; i++) {
        await save(i, steps: 6000);
      }
      final before = (await container.read(bioAgeProvider.future))!;
      expect(before.activity.missingDays, 1);
      expect(before.contributions, isNot(contains('activity')));
      await save(6, steps: 6000);
      container.read(syncStatusListenerProvider.notifier).state++;
      final after = (await container.read(bioAgeProvider.future))!;
      expect(after.activity.missingDays, 0);
      expect(after.contributions, contains('activity'));
    },
  );

  test(
    'a complete week of reported zero minutes does not use extra steps',
    () async {
      for (var i = 0; i < 7; i++) {
        await save(i, steps: 10000, minutes: 0);
      }
      final r = (await container.read(bioAgeProvider.future))!;
      expect(r.activity.minutesForScore, 0);
      expect(r.activity.usesStepEstimate, isFalse);
      expect(r.contributions, contains('activity'));
    },
  );
}
