import 'dart:io';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema 63 keeps its sessions and gains the plan change log', () async {
    final dir = await Directory.systemTemp.createTemp('fjelia-adjust-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final old = AppDatabase(NativeDatabase(file));
    await old
        .into(old.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: 's1',
            planId: 'p',
            athleteId: 'self',
            sessionDate: DateTime(2026, 11, 9),
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'running',
            sessionType: 'endurance',
            phase: 'base',
            primaryZone: 2,
            title: 'Easy run',
            plannedDurationMin: 45,
            plannedTrimp: 40,
            sessionLevel: 1,
          ),
        );
    await old
        .into(old.sessionActuals)
        .insert(SessionActualsCompanion.insert(sessionId: 's1'));
    for (final statement in const [
      'DROP TABLE plan_adjustments',
      'ALTER TABLE session_actuals DROP COLUMN match_kind',
      'ALTER TABLE session_actuals DROP COLUMN credited_by_activity_id',
      'ALTER TABLE session_actuals DROP COLUMN outcome',
      'ALTER TABLE session_actuals DROP COLUMN intensity_verdict',
      'ALTER TABLE session_actuals DROP COLUMN short_reason',
      'ALTER TABLE training_sessions DROP COLUMN locked',
      'PRAGMA user_version = 63',
    ]) {
      await old.customStatement(statement);
    }
    await old.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final s = await db.select(db.trainingSessions).getSingle();
    expect(s.title, 'Easy run');
    expect(s.locked, isFalse);
    final a = await db.select(db.sessionActuals).getSingle();
    expect(a.matchKind, isNull);
    expect(a.creditedByActivityId, isNull);
    expect(a.outcome, isNull);
    await db
        .into(db.planAdjustments)
        .insert(
          PlanAdjustmentsCompanion.insert(
            id: 'x',
            groupId: 'g',
            createdAt: DateTime(2026, 11, 9),
            kind: 'swap',
            sessionId: 's1',
            beforeJson: '{}',
            reasonCode: 'swap',
          ),
        );
    expect(await db.select(db.planAdjustments).get(), hasLength(1));
  });
}
