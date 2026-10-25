import 'dart:async';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/plan_week_provider.dart';
import 'package:fjelia/providers/planner_providers.dart';
import 'package:fjelia/providers/upcoming_plan_provider.dart';
import 'package:fjelia/services/post_workout_scorer.dart' show noActivityReason;
import 'upcoming_done_test.dart' show session, garminWorkout;

final monday = DateTime(2026, 10, 19);
DateTime day(int offset) => DateTime(2026, 10, 19 + offset, 8);
ActivityRecord activity(
  String id, {
  String name = 'Run With The Wind Modified',
  int minutes = 60,
  DateTime? at,
}) => ActivityRecord(
  id: 0,
  activityId: id,
  name: name,
  type: 'running',
  startDate: at ?? day(6),
  durationSeconds: minutes * 60,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('completed plan plus its recording is one entry and one duration', () {
    final completed = session(
      'done',
      day(6),
      status: 'completed',
      title: 'Run With The Wind Modified',
    );
    final week = buildPlanWeek(
      start: monday,
      sessions: [completed],
      activities: [activity('recorded')],
    );
    expect(week.days.last.items, hasLength(1));
    expect(week.days.last.items.single.activity?.activityId, 'recorded');
    expect(week.doneMinutes, 60);
    expect(week.plannedMinutes, 60);
  });
  test('confirmed recording cannot be stolen by a similar pending workout', () {
    final rows = markDoneEntries(
      [
        UpcomingPlanEntry(date: day(6), session: session('pending', day(6))),
        UpcomingPlanEntry(
          date: day(6),
          session: session('done', day(6), status: 'completed'),
        ),
      ],
      [activity('linked', name: 'Easy run')],
      linkedActivity: {'done': 'linked'},
    );
    expect(rows.first.doneBy, isNull);
    expect(rows.last.doneBy?.activityId, 'linked');
    expect(rows.last.completionMatch, PlanCompletionMatch.activityLink);
  });
  test('an existing link is not replaced when its activity is unavailable', () {
    final rows = markDoneEntries(
      [UpcomingPlanEntry(date: day(6), session: session('pending', day(6)))],
      [activity('different', name: 'Easy run')],
      linkedActivity: {'pending': 'missing'},
    );
    expect(rows.single.doneBy, isNull);
  });
  test(
    'a completed orphaned link rejoins the uniquely matching replacement',
    () {
      final week = buildPlanWeek(
        start: monday,
        sessions: [
          session(
            'done',
            day(6),
            status: 'completed',
            title: 'Run With The Wind Modified',
          ),
        ],
        activities: [activity('replacement')],
        linkedActivity: {'done': 'old-provider-copy'},
      );
      expect(week.days.last.items, hasLength(1));
      expect(week.days.last.items.single.activity?.activityId, 'replacement');
      expect(week.doneMinutes, 60);
    },
  );
  test('generic cycling calendars match road-bike recordings', () {
    final rows = markDoneEntries(
      [
        UpcomingPlanEntry(
          date: day(6),
          session: session(
            'ride',
            day(6),
            sport: 'cycling',
            title: 'Endurance ride',
          ),
        ),
      ],
      [activity('ride', name: 'Road ride').copyWith(type: 'road_biking')],
    );
    expect(rows.single.doneBy?.activityId, 'ride');
  });
  test('identical candidates remain planned instead of guessing', () {
    final rows = markDoneEntries(
      [
        UpcomingPlanEntry(date: day(6), session: session('am', day(6))),
        UpcomingPlanEntry(date: day(6), session: session('pm', day(6))),
      ],
      [activity('recorded', name: 'Easy run')],
    );
    expect(rows.every((e) => !e.done), isTrue);
    final week = buildPlanWeek(
      start: monday,
      sessions: rows.map((e) => e.session!).toList(),
      activities: [activity('recorded', name: 'Easy run')],
    );
    expect(
      week.days.last.items.where((e) => e.state == PlanWeekState.done),
      hasLength(1),
    );
    expect(week.doneMinutes, 60);
  });
  test('closest unambiguous durations pair both sessions once', () {
    final rows = markDoneEntries(
      [
        UpcomingPlanEntry(
          date: day(6),
          session: session(
            'short',
            day(6),
            title: 'Aerobic blocks',
            minutes: 40,
          ),
        ),
        UpcomingPlanEntry(
          date: day(6),
          session: session(
            'long',
            day(6),
            title: 'Long endurance',
            minutes: 90,
          ),
        ),
      ],
      [
        activity('long', name: 'Morning run', minutes: 88),
        activity('short', name: 'Evening run', minutes: 41),
      ],
    );
    expect(rows.map((e) => e.doneBy?.activityId), ['short', 'long']);
  });
  test('recorded start links an older manually completed workout', () {
    final rows = markDoneEntries(
      [
        UpcomingPlanEntry(
          date: day(6),
          session: session(
            'done',
            day(6),
            status: 'completed',
            title: 'Original name',
          ),
        ),
      ],
      [activity('renamed', name: 'Renamed after syncing', minutes: 25)],
      completionStarts: {'done': day(6)},
    );
    expect(rows.single.doneBy?.activityId, 'renamed');
    expect(rows.single.completionMatch, PlanCompletionMatch.recordedStart);
  });
  test('illness cancellation is not completed by an unrelated run', () {
    final week = buildPlanWeek(
      start: monday,
      sessions: [session('ill', day(6), status: 'skipped')],
      activities: [activity('extra', name: 'Easy run')],
      skipReasons: {'ill': 'Illness'},
    );
    expect(week.days.last.items, hasLength(2));
    expect(week.days.last.items.first.state, PlanWeekState.skipped);
    expect(week.days.last.items.last.hasPlan, isFalse);
  });
  test('a late sync reconciles an automatically unrecorded session', () {
    final week = buildPlanWeek(
      start: monday,
      sessions: [session('late', day(6), status: 'skipped')],
      activities: [activity('late', name: 'Easy run')],
      skipReasons: {'late': noActivityReason},
    );
    expect(week.days.last.items, hasLength(1));
    expect(week.days.last.items.single.state, PlanWeekState.done);
  });
  test('confirmed activity appears on its real day without a second entry', () {
    final week = buildPlanWeek(
      start: monday,
      sessions: [session('moved', day(1), status: 'completed')],
      activities: [activity('a', at: day(2))],
      linkedActivity: {'moved': 'a'},
    );
    expect(week.days[1].items, isEmpty);
    expect(week.days[2].items, hasLength(1));
    expect(week.doneMinutes, 60);
  });
  test(
    'completed without duration does not invent planned minutes as actual',
    () {
      final week = buildPlanWeek(
        start: monday,
        sessions: [session('done', day(6), status: 'completed')],
        activities: [],
      );
      expect(week.doneMinutes, 0);
      expect(week.days.last.items.single.minutes, isNull);
    },
  );
  test('calendar workout contributes to planned totals and is not extra', () {
    final workout = garminWorkout(day(6), 'Wind', 3600);
    final week = buildPlanWeek(
      start: monday,
      sessions: [],
      activities: [activity('a', name: 'Wind')],
      scheduled: [UpcomingPlanEntry(date: day(6), workout: workout)],
    );
    expect(week.plannedMinutes, 60);
    expect(week.doneMinutes, 60);
    expect(week.days.last.items.single.hasPlan, isTrue);
  });
  test('watch copy of a linked session is removed only on that date', () {
    final planned = session(
      's',
      day(1),
    ).copyWith(garminWorkoutId: const Value('w-Easy run'));
    final rows = mergeUpcomingPlan(
      [planned],
      [
        garminWorkout(day(1), 'Easy run', 3600),
        garminWorkout(day(2), 'Easy run', 3600),
      ],
    );
    expect(rows, hasLength(2));
    expect(rows.last.date, day(2));
  });
  for (final explicitLink in [true, false]) {
    test(
      'week provider reserves a recording owned outside the week (${explicitLink ? 'ID' : 'start'})',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        SharedPreferences.setMockInitialValues({});
        final db = AppDatabase(NativeDatabase.memory());
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            upcomingSessionsProvider.overrideWith((ref) async => []),
            scheduledWorkoutsProvider.overrideWith((ref) async => []),
          ],
        );
        final subscription = container.listen(
          planWeekProvider(monday),
          (previous, next) {},
          fireImmediately: true,
        );
        try {
          await db
              .into(db.trainingPlans)
              .insert(
                TrainingPlansCompanion.insert(
                  id: 'p',
                  athleteId: 'self',
                  startDate: day(-7),
                  endDate: day(14),
                  status: 'active',
                  generatedAt: day(-7),
                ),
              );
          await db.into(db.trainingSessions).insert(session('pending', day(6)));
          await db
              .into(db.trainingSessions)
              .insert(session('earlier', day(-1), status: 'completed'));
          await db
              .into(db.activityRecords)
              .insert(activity('owned', name: 'Easy run'));
          await db
              .into(db.sessionActuals)
              .insert(
                SessionActualsCompanion.insert(
                  sessionId: 'earlier',
                  activityId: explicitLink
                      ? const Value('owned')
                      : const Value.absent(),
                  startedAt: explicitLink
                      ? const Value.absent()
                      : Value(day(6)),
                ),
              );
          final week = await container.read(planWeekProvider(monday).future);
          final items = week.days.last.items;
          expect(items, hasLength(2));
          expect(items.first.session?.id, 'pending');
          expect(items.first.state, PlanWeekState.planned);
          expect(items.first.activity, isNull);
          expect(items.last.activity?.activityId, 'owned');
          expect(week.doneMinutes, 60);
        } finally {
          subscription.close();
          container.dispose();
          await db.close();
        }
      },
    );
  }
  test('week provider reacts to a recording without another sync', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        upcomingSessionsProvider.overrideWith((ref) async => []),
        scheduledWorkoutsProvider.overrideWith((ref) async => []),
      ],
    );
    final subscription = container.listen(
      planWeekProvider(monday),
      (previous, next) {},
      fireImmediately: true,
    );
    try {
      await db
          .into(db.trainingSessions)
          .insert(
            session(
              'done',
              day(6),
              status: 'completed',
              title: 'Run With The Wind Modified',
            ),
          );
      await db
          .into(db.sessionActuals)
          .insert(
            SessionActualsCompanion.insert(
              sessionId: 'done',
              activityId: const Value('recorded'),
            ),
          );
      final before = await container.read(planWeekProvider(monday).future);
      expect(before.days.last.items.single.activity, isNull);
      final received = Completer<PlanWeek>();
      final sub = container.listen(planWeekProvider(monday), (previous, next) {
        final week = next.valueOrNull;
        if (week != null && week.doneMinutes == 60 && !received.isCompleted) {
          received.complete(week);
        }
      });
      await db.into(db.activityRecords).insert(activity('recorded'));
      final after = await received.future.timeout(const Duration(seconds: 5));
      expect(after.days.last.items, hasLength(1));
      expect(after.days.last.items.single.activity?.activityId, 'recorded');
      sub.close();
    } finally {
      subscription.close();
      container.dispose();
      await db.close();
    }
  });
}
