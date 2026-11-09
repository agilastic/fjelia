import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/plan_week_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> session(
    String id,
    DateTime day,
    String title, {
    String status = 'planned',
    int minutes = 45,
  }) => db
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
          primaryZone: 2,
          title: title,
          plannedDurationMin: minutes,
          plannedTrimp: 40,
          sessionLevel: 1,
          status: Value(status),
        ),
      );

  Future<void> activity(String id, DateTime at, String name, int minutes) => db
      .into(db.activityRecords)
      .insert(
        ActivityRecordsCompanion.insert(
          activityId: id,
          name: name,
          type: 'running',
          startDate: at,
          durationSeconds: minutes * 60,
          trainingLoad: const Value(60),
        ),
      );

  test('the week as it went: done, skipped with reason, missed, '
      'changes and extra training', () async {
    final today = DateTime(2026, 11, 9, 18);
    await session('s1', DateTime(2026, 11, 5), 'Easy run', status: 'completed');
    await activity('a1', DateTime(2026, 11, 5, 7), 'Morning run', 44);
    await db
        .into(db.sessionActuals)
        .insert(
          SessionActualsCompanion.insert(
            sessionId: 's1',
            activityId: const Value('a1'),
            executionScore: const Value(92),
          ),
        );
    await session('s2', DateTime(2026, 11, 6), 'Tempo 3x12', status: 'skipped');
    await db
        .into(db.sessionActuals)
        .insert(
          SessionActualsCompanion.insert(
            sessionId: 's2',
            skipReason: const Value('Illness'),
          ),
        );
    await session('s3', DateTime(2026, 11, 7), 'Long run', minutes: 95);
    await activity('a2', DateTime(2026, 11, 8, 10), 'Bike with friends', 120);
    await db
        .into(db.planAdjustments)
        .insert(
          PlanAdjustmentsCompanion.insert(
            id: 'c1',
            groupId: 'g',
            createdAt: DateTime(2026, 11, 6, 8),
            kind: 'swap',
            sessionId: 's2',
            beforeJson: '{}',
            reasonCode: 'readiness_low',
          ),
        );
    // Outside the week: not listed.
    await session('s0', DateTime(2026, 11, 1), 'Old run');

    final lines = await planWeekLines(db, today);
    final text = lines.join('\n');
    expect(text, isNot(contains('Old run')));
    expect(
      lines.firstWhere((l) => l.contains('Easy run')),
      allOf(
        contains('status:done'),
        contains('actual:44min Morning run'),
        contains('execution:92/100'),
      ),
    );
    expect(
      lines.firstWhere((l) => l.contains('Tempo 3x12')),
      allOf(contains('status:skipped'), contains('reason:Illness')),
    );
    expect(
      lines.firstWhere((l) => l.contains('Long run')),
      contains('status:missed'),
    );
    expect(
      text,
      contains(
        '[PlanWeek:Change,date:2026-11-06 Fri,kind:swap,session:Tempo 3x12,reason:readiness_low',
      ),
    );
    expect(
      text,
      contains('[PlanWeek:Extra,date:2026-11-08 Sun,name:Bike with friends'),
    );
    expect(text, isNot(contains('name:Morning run')));
  });
}
