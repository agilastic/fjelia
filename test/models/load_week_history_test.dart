import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/load_week_history.dart';

ActivityRecord activity(
  String id,
  DateTime date, {
  String? zones,
  int minutes = 60,
  double? elevation,
}) => ActivityRecord(
  id: 0,
  activityId: id,
  name: id,
  type: 'running',
  startDate: date,
  durationSeconds: minutes * 60,
  hrZonesJson: zones,
  totalElevation: elevation,
);
void main() {
  final selected = DateTime(2026, 10, 25);
  final zones = jsonEncode({
    'zone1': 20,
    'zone2': 50,
    'zone3': 10,
    'zone4': 15,
    'zone5': 5,
  });
  test(
    'twelve contiguous weeks include current, historical and empty weeks',
    () {
      final weeks = buildLoadWeekHistory(
        through: selected,
        activities: [
          activity('now', selected, zones: zones),
          activity('previous', DateTime(2026, 10, 14), zones: zones),
        ],
      );
      expect(weeks, hasLength(12));
      expect(weeks.last.start, DateTime(2026, 10, 19));
      expect(weeks[10].start, DateTime(2026, 10, 12));
      expect(weeks[10].easyPercent, closeTo(70, .001));
      expect(weeks.first.activities, 0);
    },
  );
  test('missing and malformed zones retain activity and elevation history', () {
    final weeks = buildLoadWeekHistory(
      through: selected,
      activities: [
        activity('none', DateTime(2026, 10, 12), elevation: 150),
        activity('broken', DateTime(2026, 10, 13), zones: 'not json'),
        activity('zero', DateTime(2026, 10, 14), zones: '{"zone1":0}'),
        activity(
          'negative',
          DateTime(2026, 10, 14),
          zones: '{"zone1":-5,"zone2":100}',
        ),
        activity('seconds', DateTime(2026, 10, 14), zones: '{"zone2":3600}'),
      ],
    );
    expect(weeks[10].activities, 5);
    expect(weeks[10].activitiesWithZones, 0);
    expect(weeks[10].easyPercent, isNull);
    expect(weeks[10].elevation, 150);
  });
  test('durations are time-weighted rather than averaging percentages', () {
    final week = buildLoadWeekHistory(
      through: selected,
      activities: [
        activity('easy', selected, zones: '{"zone2":100}', minutes: 180),
        activity('hard', selected, zones: '{"zone5":100}', minutes: 60),
      ],
    ).last;
    expect(week.classifiedMinutes, 240);
    expect(week.easyPercent, 75);
    expect(week.activitiesWithZones, 2);
  });
  test(
    'recorded samples restore old zones without inventing a full workout',
    () {
      final samples = jsonEncode([
        for (var i = 0; i < 13; i++) {'hr': 125, 't': 1700000000000 + i * 2000},
      ]);
      final week = buildLoadWeekHistory(
        through: selected,
        activities: [
          activity('partial', selected).copyWith(metricsJson: Value(samples)),
        ],
        runningZones: [100, 120, 140, 160, 180],
      ).last;
      expect(week.activitiesWithZones, 1);
      expect(week.activitiesFromSamples, 1);
      expect(week.easyPercent, 100);
      expect(week.classifiedMinutes, closeTo(25 / 60, .001));
    },
  );
  test('untimed samples cannot establish historical zone minutes', () {
    final week = buildLoadWeekHistory(
      through: selected,
      activities: [
        activity('untimed', selected).copyWith(
          metricsJson: Value(
            jsonEncode([
              for (var i = 0; i < 15; i++) {'hr': 125},
            ]),
          ),
        ),
      ],
      runningZones: [100, 120, 140, 160, 180],
    ).last;
    expect(week.activitiesWithZones, 0);
    expect(week.easyPercent, isNull);
  });
  test('stored zone data takes precedence over sample reconstruction', () {
    final week = buildLoadWeekHistory(
      through: selected,
      activities: [
        activity('known', selected, zones: '{"zone4":100}').copyWith(
          metricsJson: Value(
            jsonEncode([
              for (var i = 0; i < 15; i++)
                {'hr': 125, 't': 1700000000000 + i * 1000},
            ]),
          ),
        ),
      ],
      runningZones: [100, 120, 140, 160, 180],
    ).last;
    expect(week.activitiesFromSamples, 0);
    expect(week.easyPercent, 0);
    expect(week.classifiedMinutes, 60);
  });
  test('Sunday starts and year changes preserve twelve consecutive weeks', () {
    final weeks = buildLoadWeekHistory(
      through: DateTime(2027, 1, 3),
      mondayFirst: false,
      activities: [activity('old', DateTime(2025), zones: zones)],
    );
    expect(weeks.last.start, DateTime(2027, 1, 3));
    expect(weeks[10].start, DateTime(2026, 12, 27));
    expect(weeks.every((w) => w.activities == 0), isTrue);
  });
}
