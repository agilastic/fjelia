import 'package:fjelia/l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/garmin_data.dart';
import 'package:fjelia/providers/upcoming_plan_provider.dart';
import 'package:fjelia/screens/planner/plan_overview_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingSession session(
  String id,
  DateTime day, {
  String status = 'planned',
  String sport = 'running',
  String title = 'Easy run',
  int minutes = 60,
}) => TrainingSession(
  id: id,
  planId: 'p',
  athleteId: 'self',
  sessionDate: day,
  sessionNumber: 1,
  weekNumber: 1,
  sport: sport,
  sessionType: 'long',
  phase: 'base',
  primaryZone: 2,
  title: title,
  tspAdjusted: false,
  plannedDurationMin: minutes,
  plannedTrimp: 60,
  sessionLevel: 5,
  status: status,
  warmUpCompletionPct: 0,
  mainSetCompletionPct: 0,
  createdByCoach: false,
  adjustedByCoach: false,
  addedByAthlete: false,
  historical: false,
  indoor: false,
  isMovedFromDifferentWeek: false,
);

ScheduledWorkout garminWorkout(DateTime day, String name, int seconds) =>
    ScheduledWorkout(
      workoutId: 'w-$name',
      scheduleId: 's-$name',
      name: name,
      sportType: 'running',
      scheduledDate: day,
      estimatedDuration: Duration(seconds: seconds),
    );

void main() {
  late AppDatabase db;
  final today = DateTime(2026, 10, 25);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<ActivityRecord> activity(
    String id,
    String name, {
    String type = 'running',
    DateTime? start,
    int minutes = 59,
    double km = 9.4,
  }) async {
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: name,
            type: type,
            startDate: start ?? DateTime(2026, 10, 25, 8),
            durationSeconds: minutes * 60,
            distanceMeters: Value(km * 1000),
            source: const Value('garmin'),
          ),
        );
    return (db.select(
      db.activityRecords,
    )..where((t) => t.activityId.equals(id))).getSingle();
  }

  group('what was done shows against what was planned', () {
    test('a Garmin workout is done by the activity named after it', () async {
      final run = await activity(
        'a1',
        'Hemmingen - Run With The Wind Modified',
      );
      final rows = markDoneEntries(
        [
          UpcomingPlanEntry(
            date: today,
            workout: garminWorkout(today, 'Run With The Wind Modified', 3570),
          ),
        ],
        [run],
      );
      expect(rows.single.done, isTrue);
      expect(rows.single.doneBy!.activityId, 'a1');
    });

    test(
      'a planned session is done by an activity of its sport and length',
      () async {
        final run = await activity('a2', 'Morning run', minutes: 58);
        final rows = markDoneEntries(
          [UpcomingPlanEntry(date: today, session: session('s', today))],
          [run],
        );
        expect(rows.single.done, isTrue);
        // A short jog is not the planned long run.
        final jog = await activity('a3', 'Jog', minutes: 25);
        expect(
          markDoneEntries(
            [UpcomingPlanEntry(date: today, session: session('s', today))],
            [jog],
          ).single.done,
          isFalse,
        );
      },
    );

    test('a recording that completed the plan session also completes the '
        'Garmin workout with the same name', () async {
      final run = await activity(
        'a9',
        'Hemmingen - Trail Long Run with Vert',
        minutes: 83,
        km: 12.4,
      );
      final rows = markDoneEntries(
        [
          UpcomingPlanEntry(
            date: today,
            workout: garminWorkout(today, 'Trail Long Run with Vert', 88 * 60),
          ),
        ],
        [run],
        // The recording is already linked to another (completed) session.
        linkedActivity: {'plan-session': 'a9'},
      );
      expect(rows.single.done, isTrue);
      expect(rows.single.doneBy!.activityId, 'a9');
    });

    test('a different name is not done by a linked recording', () async {
      final run = await activity('a10', 'Morning run', minutes: 83);
      final rows = markDoneEntries(
        [
          UpcomingPlanEntry(
            date: today,
            workout: garminWorkout(today, 'Trail Long Run with Vert', 88 * 60),
          ),
        ],
        [run],
        linkedActivity: {'plan-session': 'a10'},
      );
      expect(rows.single.done, isFalse);
    });

    test('another day, another sport, or no activity: not done', () async {
      final yesterday = await activity(
        'b1',
        'Run With The Wind Modified',
        start: DateTime(2026, 10, 24, 8),
      );
      final ride = await activity('b2', 'Easy ride', type: 'cycling');
      final entry = UpcomingPlanEntry(
        date: today,
        workout: garminWorkout(today, 'Run With The Wind Modified', 3570),
      );
      expect(markDoneEntries([entry], [yesterday, ride]).single.done, isFalse);
      expect(markDoneEntries([entry], const []).single.done, isFalse);
    });

    test('one activity does one entry, and the name beats a guess', () async {
      final run = await activity('c1', 'Tempo Blocks', minutes: 60);
      final rows = markDoneEntries(
        [
          UpcomingPlanEntry(
            date: today,
            session: session('plain', today, title: 'Easy run'),
          ),
          UpcomingPlanEntry(
            date: today,
            session: session('named', today, title: 'Tempo Blocks'),
          ),
        ],
        [run],
      );
      expect(rows[0].done, isFalse);
      expect(rows[1].done, isTrue);
    });

    test(
      'a skipped entry is left alone; a finished session joins its activity',
      () async {
        final run = await activity('d1', 'Easy run');
        final rows = markDoneEntries(
          [
            UpcomingPlanEntry(
              date: today,
              session: session('skipped', today, status: 'skipped'),
            ),
            UpcomingPlanEntry(
              date: today,
              session: session('finished', today, status: 'completed'),
            ),
          ],
          [run],
        );
        expect(rows[0].done, isFalse);
        expect(rows[0].doneBy, isNull);
        expect(rows[1].done, isTrue);
        expect(rows[1].doneBy?.activityId, 'd1');
      },
    );
  });

  group('the list', () {
    Future<void> show(WidgetTester tester, List<UpcomingPlanEntry> entries) =>
        tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: UpcomingWorkoutList(entries: entries),
              ),
            ),
          ),
        );

    testWidgets(
      'a done workout is struck through, checked, and says what was done',
      (tester) async {
        final run = await activity(
          'e1',
          'Hemmingen - Run With The Wind Modified',
        );
        final entries = markDoneEntries(
          [
            UpcomingPlanEntry(
              date: DateTime.now(),
              workout: garminWorkout(
                DateTime.now(),
                'Run With The Wind Modified',
                3570,
              ),
            ),
            UpcomingPlanEntry(
              date: DateTime.now(),
              session: session(
                'open',
                DateTime.now(),
                title: 'Evening spin',
                sport: 'cycling_road',
              ),
            ),
          ],
          [
            ActivityRecord(
              id: run.id,
              activityId: run.activityId,
              name: run.name,
              type: run.type,
              startDate: DateTime.now(),
              durationSeconds: run.durationSeconds,
              distanceMeters: run.distanceMeters,
              source: run.source,
            ),
          ],
        );
        await show(tester, entries);
        await tester.pump(const Duration(milliseconds: 500));
        final title = tester.widget<Text>(
          find.text('Run With The Wind Modified'),
        );
        expect(title.style?.decoration, TextDecoration.lineThrough);
        expect(find.text('Done · 0h59m · 9.4 km'), findsOneWidget);
        expect(find.byKey(const Key('done-check')), findsOneWidget);
        // What is still to do looks as before.
        final open = tester.widget<Text>(find.text('Evening spin'));
        expect(open.style?.decoration, isNull);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
    );
  });
}
