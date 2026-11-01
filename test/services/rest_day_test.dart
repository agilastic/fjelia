import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations_en.dart';
import 'package:fjelia/services/ai_context_toon_builder.dart';
import 'package:fjelia/services/briefing_brief.dart';
import 'package:fjelia/services/plan_day.dart';
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
}
