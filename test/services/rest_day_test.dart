import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations_en.dart';
import 'package:fjelia/services/ai_context_toon_builder.dart';
import 'package:fjelia/services/briefing_brief.dart';
import 'package:fjelia/services/plan_day.dart';
import 'package:fjelia_core/models/training_windows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> plan() => db
      .into(db.trainingPlans)
      .insert(
        TrainingPlansCompanion.insert(
          id: 'p',
          athleteId: 'self',
          startDate: day(-20),
          endDate: day(100),
          status: 'active',
          generatedAt: day(-20),
        ),
      );

  Future<void> session(String id, DateTime date, String status) => db
      .into(db.trainingSessions)
      .insert(
        TrainingSessionsCompanion.insert(
          id: id,
          planId: 'p',
          athleteId: 'self',
          sessionDate: date,
          sessionNumber: 1,
          weekNumber: 1,
          sport: 'running',
          sessionType: 'key',
          phase: 'base',
          primaryZone: 3,
          title: 'Run',
          plannedDurationMin: 45,
          plannedTrimp: 50,
          sessionLevel: 4,
          status: Value(status),
        ),
      );

  Future<String> context() => AiContextToonBuilder(db).build(null, '', null);

  group('planned rest day', () {
    test('a plan day without anything scheduled is a rest day', () async {
      await plan();
      await session('tomorrow', day(1), 'planned');
      expect(await isPlannedRestDay(db, today), isTrue);
      expect(await isPlannedRestDay(db, day(1)), isFalse);
    });

    test('without a plan there is no planned rest day', () async {
      expect(await isPlannedRestDay(db, today), isFalse);
    });

    test('a completed or cancelled session is not a rest day', () async {
      await plan();
      await session('done', today, 'completed');
      await session('skip', day(1), 'skipped');
      expect(await isPlannedRestDay(db, today), isFalse);
      expect(await isPlannedRestDay(db, day(1)), isFalse);
    });
  });

  group('coach context', () {
    test('a planned rest day is said so, also in the briefing', () async {
      await plan();
      final text = await context();
      expect(text, contains('[TodayWorkout:Status:rest_day,Planned:yes'));
      final brief = BriefingBrief.parse(text)!;
      expect(brief.restDay, isTrue);
      expect(brief.toModelText(), contains('planned rest day'));
    });

    test('a finished session is done, not a rest day', () async {
      await plan();
      await session('done', today, 'completed');
      final text = await context();
      expect(text, contains('[TodayWorkout:Status:done,PlanSessionsDone:1'));
      expect(text, isNot(contains('Status:rest_day')));
      expect(BriefingBrief.parse(text)!.restDay, isFalse);
    });

    test('a synced activity that does the session finishes it, as in the '
        'Plan', () async {
      await plan();
      await session('run', today, 'planned');
      // Still `planned` in the database: the Plan matches it by sport, day
      // and length.
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'garmin-1',
              name: 'Morning run',
              type: 'running',
              startDate: today.add(const Duration(hours: 7)),
              durationSeconds: 47 * 60,
            ),
          );
      final text = await AiContextToonBuilder(
        db,
        openProposal: () => 'rest',
      ).build(null, '', null);
      expect(text, contains('[TodayWorkout:Status:done,PlanSessionsDone:1'));
      final brief = BriefingBrief.parse(text)!;
      expect(brief.today, isEmpty);
      expect(brief.done, ['running/47']);
      // The morning proposal to drop the session has nothing left to change.
      expect(brief.proposal, isNull);
      expect(brief.toModelText(), contains('No further scheduled sessions'));
      expect(
        brief.localText(AppLocalizationsEn()),
        isNot(contains('planned today')),
      );
    });

    test('two sessions today: the brief says which first and when', () async {
      await plan();
      await session('run', today, 'planned');
      await db
          .into(db.trainingSessions)
          .insert(
            TrainingSessionsCompanion.insert(
              id: 'gym',
              planId: 'p',
              athleteId: 'self',
              sessionDate: today,
              sessionNumber: 2,
              weekNumber: 1,
              sport: 'strength',
              sessionType: 'key',
              phase: 'base',
              primaryZone: 3,
              title: 'Gym',
              plannedDurationMin: 45,
              plannedTrimp: 40,
              sessionLevel: 4,
            ),
          );
      // The whole day open, so the order does not depend on the clock.
      var windows = const TrainingWindows();
      for (var slot = 0; slot < TrainingWindows.slotsPerDay; slot++) {
        windows = windows.withSlot(today.weekday, slot, true);
      }
      final brief = BriefingBrief.parse(
        await AiContextToonBuilder(
          db,
          trainingWindows: () async => windows,
        ).build(null, '', null),
      )!;
      expect(brief.order.map((o) => o.split('@').first), [
        'running/45',
        'strength/45',
      ]);
      expect(brief.toModelText(), contains('Order today'));
    });

    test('a different sport does not finish the session', () async {
      await plan();
      await session('run', today, 'planned');
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'garmin-2',
              name: 'Ride',
              type: 'cycling',
              startDate: today.add(const Duration(hours: 7)),
              durationSeconds: 45 * 60,
            ),
          );
      final brief = BriefingBrief.parse(
        await AiContextToonBuilder(
          db,
          openProposal: () => 'rest',
        ).build(null, '', null),
      )!;
      expect(brief.today, ['running/45']);
      expect(brief.proposal, 'rest');
    });

    test('without a plan nothing is scheduled, and no rest day', () async {
      final text = await context();
      expect(text, contains('[TodayWorkout:Status:none'));
      expect(BriefingBrief.parse(text)!.restDay, isFalse);
    });
  });

  test('the brief keeps the rest day through its line form', () {
    final l = AppLocalizationsEn();
    const brief = BriefingBrief(readiness: 'green', restDay: true);
    final back = BriefingBrief.parse(brief.toLine())!;
    expect(back.restDay, isTrue);
    expect(back.localText(l), contains('Today is a planned rest day.'));
    expect(back.scheduleInstruction(l), contains('Do not suggest a workout'));
    // A day with sessions never claims rest.
    const busy = BriefingBrief(readiness: 'green', today: ['running/45']);
    expect(busy.localText(l), isNot(contains('rest day')));
  });

  test('the coach sees absences and training times, not the note', () async {
    await db
        .into(db.absences)
        .insert(
          AbsencesCompanion.insert(
            kind: 'illness',
            startDay: day(-1),
            endDay: day(2),
            note: const Value('Fever, stayed in bed'),
            createdAt: DateTime.now(),
          ),
        );
    var windows = const TrainingWindows();
    for (var slot = 34; slot < 40; slot++) {
      windows = windows.withSlot(2, slot, true);
    }
    final text = await AiContextToonBuilder(
      db,
      trainingWindows: () async => windows,
    ).build(null, '', null);
    expect(text, contains('[Absences:1]'));
    expect(text, contains('Kind:illness'));
    expect(text, contains(',Now]'));
    expect(text, isNot(contains('Fever')));
    expect(text, contains('Tue=17:00-20:00'));
    expect(text, contains('Mon=none'));
    // The briefing knows today and tomorrow are taken by the illness.
    final brief = BriefingBrief.parse(text)!;
    expect(brief.away, 'illness');
    expect(brief.awayTomorrow, 'illness');
    expect(brief.backFrom, isNull);
  });

  test('the first week back from an illness reaches the brief', () async {
    await db
        .into(db.absences)
        .insert(
          AbsencesCompanion.insert(
            kind: 'illness',
            startDay: day(-6),
            endDay: day(-2),
            createdAt: DateTime.now(),
          ),
        );
    final brief = BriefingBrief.parse(
      await AiContextToonBuilder(db).build(null, '', null),
    )!;
    expect(brief.away, isNull);
    expect(brief.backFrom, 'illness');
  });

  test('without a race the coach knows the own aim of the athlete', () async {
    final text = await AiContextToonBuilder(
      db,
      casualGoal: () async => 'fun',
    ).build(null, '', null);
    expect(text, contains('[Goal:NoRace,Aim:fun'));
    expect(text, contains('every session easy'));
  });
}
