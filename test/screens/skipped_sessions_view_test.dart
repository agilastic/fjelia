import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/calendar_activity.dart';
import 'package:fjelia/providers/activity_calendar_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/upcoming_plan_provider.dart';
import 'package:fjelia/screens/planner/plan_calendar_markers.dart';
import 'package:fjelia/screens/planner/plan_overview_cards.dart';
import 'package:fjelia/models/garmin_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingSession session(
  String id,
  DateTime day, {
  String status = 'planned',
  String? garminWorkoutId,
}) => TrainingSession(
  id: id,
  planId: 'p',
  athleteId: 'self',
  sessionDate: day,
  sessionNumber: 1,
  weekNumber: 1,
  sport: 'running',
  sessionType: 'key',
  phase: 'base',
  primaryZone: 2,
  title: 'Tempo Run $id',
  tspAdjusted: false,
  plannedDurationMin: 45,
  plannedTrimp: 60,
  sessionLevel: 5,
  status: status,
  garminWorkoutId: garminWorkoutId,
  warmUpCompletionPct: 0,
  mainSetCompletionPct: 0,
  createdByCoach: false,
  adjustedByCoach: false,
  addedByAthlete: false,
  historical: false,
  indoor: false,
  isMovedFromDifferentWeek: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('upcoming list', () {
    test('a skipped session stays in the plan with its reason', () {
      final rows = mergeUpcomingPlan(
        [
          session('a', DateTime(2026, 10, 27)),
          session('b', DateTime(2026, 10, 28), status: 'skipped'),
        ],
        const [],
        skipReasons: {'b': 'Illness', 'a': 'ignored for a planned one'},
      );
      expect(rows.map((e) => e.session!.id), ['a', 'b']);
      expect(rows[0].skipped, isFalse);
      expect(rows[0].skipReason, isNull);
      expect(rows[1].skipped, isTrue);
      expect(rows[1].skipReason, 'Illness');
    });

    test('its watch workout does not reappear as a separate entry', () {
      final rows = mergeUpcomingPlan(
        [
          session(
            'b',
            DateTime(2026, 10, 28),
            status: 'skipped',
            garminWorkoutId: 'w1',
          ),
        ],
        [
          ScheduledWorkout(
            workoutId: 'w1',
            scheduleId: 's1',
            name: 'Tempo',
            sportType: 'running',
            scheduledDate: DateTime(2026, 10, 28),
          ),
        ],
        skipReasons: const {'b': 'Travel'},
      );
      expect(rows, hasLength(1));
    });

    testWidgets('the tile is struck through and says why', (tester) async {
      final entries = mergeUpcomingPlan(
        [
          session('a', DateTime(2026, 10, 27)),
          session('b', DateTime(2026, 10, 27), status: 'skipped'),
        ],
        const [],
        skipReasons: const {'b': 'Illness'},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UpcomingWorkoutList(entries: entries),
            ),
          ),
        ),
      );
      expect(find.text('SKIPPED'), findsOneWidget);
      expect(find.text('Illness · 45 min dropped'), findsOneWidget);
      final title = tester.widget<Text>(find.text('Tempo Run b'));
      expect(title.style?.decoration, TextDecoration.lineThrough);
      final planned = tester.widget<Text>(find.text('Tempo Run a'));
      expect(planned.style?.decoration, isNull);
      expect(find.text('45 min · TRIMP 60 · Z2'), findsOneWidget);
    });
  });

  group('month calendar', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> insert(String id, String status, {String? reason}) async {
      await db
          .into(db.trainingSessions)
          .insert(
            TrainingSessionsCompanion.insert(
              id: id,
              planId: 'p',
              athleteId: 'self',
              sessionDate: DateTime(2026, 10, 28),
              sessionNumber: 1,
              weekNumber: 1,
              sport: 'running',
              sessionType: 'key',
              phase: 'base',
              primaryZone: 2,
              title: 'Run $id',
              plannedDurationMin: 40,
              plannedTrimp: 40,
              sessionLevel: 3,
              status: Value(status),
            ),
          );
      if (reason != null) {
        await db
            .into(db.sessionActuals)
            .insert(
              SessionActualsCompanion.insert(
                sessionId: id,
                skipReason: Value(reason),
              ),
            );
      }
    }

    test('a cancelled session is marked, an unconfirmed one is not', () async {
      await insert('ill', 'skipped', reason: 'Illness');
      await insert('missing', 'skipped', reason: 'No matching activity');
      await insert('planned', 'planned');
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      final entries = await container.read(
        planCalendarActivitiesProvider(DateTime(2026, 10)).future,
      );
      final skipped = entries.where((e) => e.skipped).toList();
      expect(skipped.map((e) => e.title), ['Run ill']);
      expect(skipped.single.skipReason, 'Illness');
      expect(skipped.single.statusLabel, 'Skipped · Illness');
      expect(entries.where((e) => !e.skipped).map((e) => e.title), [
        'Run planned',
      ]);
    });

    testWidgets('the marker is a cross, not a dot', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarActivityBubbles(
              activities: [
                CalendarActivity(
                  date: DateTime(2026, 10, 28),
                  sport: 'running',
                  title: 'Run',
                  completed: false,
                  skipped: true,
                  skipReason: 'Travel',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(
        find.bySemanticsLabel('Run, running, skipped · travel'),
        findsOneWidget,
      );
    });
  });
}
