import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/season_context.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> session(
    String id,
    DateTime day, {
    String sport = 'running',
    String type = 'endurance',
    String status = 'planned',
    int minutes = 60,
    String phase = 'base',
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
          sport: sport,
          sessionType: type,
          phase: phase,
          primaryZone: 2,
          title: id,
          plannedDurationMin: minutes,
          plannedTrimp: 40,
          sessionLevel: 1,
          status: Value(status),
        ),
      );

  test('past weeks from activities, coming weeks from the plan to the last '
      'goal', () async {
    final today = DateTime(2026, 11, 11); // a Wednesday; week of 9 Nov
    // Last week (2 Nov): a run and a long ride; one planned run not done.
    for (final (id, at, type, min) in [
      ('a1', DateTime(2026, 11, 3, 7), 'running', 50),
      ('a2', DateTime(2026, 11, 7, 9), 'cycling', 180),
    ]) {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: id,
              name: id,
              type: type,
              startDate: at,
              durationSeconds: min * 60,
              trainingLoad: const Value(100),
            ),
          );
    }
    await session('past', DateTime(2026, 11, 5), status: 'skipped');
    // Coming weeks: this week and the race week.
    await session('k1', DateTime(2026, 11, 12), type: 'key', minutes: 50);
    await session('l1', DateTime(2026, 11, 15), minutes: 120);
    await session('t1', DateTime(2026, 11, 24), phase: 'taper', minutes: 40);
    await db
        .into(db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: 'g1',
            athleteId: 'self',
            name: 'Autumn Half',
            primarySport: 'running',
            distanceM: 21097,
            raceDate: DateTime(2026, 11, 29),
            priority: 'A',
            source: 'manual',
            createdAt: DateTime(2026, 10, 1),
          ),
        );

    final lines = await seasonWeekLines(db, today, historyWeeks: 2);
    final history = lines.where((l) => l.startsWith('[SeasonHistory')).toList();
    final plan = lines.where((l) => l.startsWith('[SeasonPlan')).toList();
    expect(history, hasLength(2));
    expect(
      history.last,
      allOf(
        contains('start:2026-11-02'),
        contains('hours:cycling 3.0 running 0.8'),
        contains('load:200'),
        contains('longest:180min cycling'),
        contains('sessions:2'),
        contains('notDone:1'),
      ),
    );
    // This week up to the race week, nothing after the last goal.
    expect(plan, hasLength(3));
    expect(
      plan.first,
      allOf(
        contains('start:2026-11-09'),
        contains('hours:running 2.8'),
        contains('longest:120min running'),
        contains('key:1'),
      ),
    );
    expect(
      plan.last,
      allOf(
        contains('start:2026-11-23'),
        contains('phase:taper'),
        contains('race:Autumn Half (A)'),
      ),
    );
  });

  test('the season check names goals by priority, sport and date', () async {
    expect(await seasonCheckLines(db), isEmpty);
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            startDate: DateTime(2026, 11, 2),
            endDate: DateTime(2027, 6, 1),
            status: 'active',
            generatedAt: DateTime(2026, 11, 2),
            seasonJson: Value(
              jsonEncode({
                'outcome': 'insufficientData',
                'goals': {
                  'g1': {
                    'name': 'Lake Run',
                    'priority': 'A',
                    'sport': 'running',
                    'date': '2027-04-12',
                  },
                },
                'conflicts': [],
                'summary': [
                  'In 6 of 40 weeks the hours do not cover Lake Run.',
                ],
              }),
            ),
          ),
        );
    final lines = await seasonCheckLines(db);
    expect(lines.first, '[SeasonCheck:Outcome,insufficientData]');
    expect(
      lines,
      contains(
        '[SeasonCheckNote:In 6 of 40 weeks the hours do not cover '
        'A-goal running 2027-04-12.]',
      ),
    );
    expect(lines.join(), isNot(contains('Lake Run')));
  });
}
