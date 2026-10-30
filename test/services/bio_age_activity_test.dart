import 'package:fjelia/services/bio_age_activity.dart';
import 'package:fjelia/services/bio_age_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 30, 8, 43);

  List<BioAgeActivityDay> week({double? minutes, int? steps}) => [
    for (var i = 0; i < 7; i++)
      BioAgeActivityDay(
        date: DateTime(today.year, today.month, today.day - i),
        reportedMinutes: minutes,
        steps: steps,
      ),
  ];

  BioAgeResult result(BioAgeActivity activity) => estimateBioAge(
    BioAgePerson(sex: 'm', age: 45, vo2max: 52, activity: activity),
  );

  test('reported minutes take priority even when a day has many steps', () {
    final input = week(minutes: 0, steps: 10000);
    input[0] = BioAgeActivityDay(
      date: today,
      reportedMinutes: 72,
      steps: 10000,
    );
    final activity = BioAgeActivity.fromDays(input, today: today);
    expect(activity.minutesForScore, 72);
    expect(activity.reportedDays, 7);
    expect(activity.estimatedWalkingMinutes, 0);
    expect(activity.usesStepEstimate, isFalse);
  });

  test('step-only dates produce explicitly estimated walking time', () {
    final activity = BioAgeActivity.fromDays(week(steps: 10000), today: today);
    expect(activity.reportedDays, 0);
    expect(activity.stepEstimatedDays, 7);
    expect(activity.estimatedWalkingMinutes, 700);
    expect(activity.minutesForScore, 700);
    expect(activity.usesStepEstimate, isTrue);
  });

  test('a mixed week adds sources from different dates only', () {
    final input = week(steps: 6000);
    input[0] = BioAgeActivityDay(
      date: today,
      reportedMinutes: 72,
      steps: 12000,
    );
    input[1] = BioAgeActivityDay(
      date: DateTime(2026, 10, 29),
      reportedMinutes: 0,
      steps: 12000,
    );
    final activity = BioAgeActivity.fromDays(input, today: today);
    expect(activity.reportedMinutes, 72);
    expect(activity.estimatedWalkingMinutes, 300);
    expect(activity.minutesForScore, 372);
    expect(activity.reportedDays, 2);
    expect(activity.stepEstimatedDays, 5);
  });

  test(
    'explicit zero minutes remain known zero rather than a step fallback',
    () {
      final activity = BioAgeActivity.fromDays(
        week(minutes: 0, steps: 15000),
        today: today,
      );
      expect(activity.minutesForScore, 0);
      expect(activity.isComplete, isTrue);
      expect(activity.usesStepEstimate, isFalse);
    },
  );

  test('explicit zero steps can establish a day while absent steps cannot', () {
    final zero = BioAgeActivity.fromDays(week(steps: 0), today: today);
    final absent = BioAgeActivity.fromDays(week(), today: today);
    expect(zero.minutesForScore, 0);
    expect(zero.coveredDays, 7);
    expect(absent.minutesForScore, isNull);
    expect(absent.coveredDays, 0);
  });

  test(
    'partial data is not extrapolated or converted to an inactivity penalty',
    () {
      final partial = BioAgeActivity.fromDays(
        week(minutes: 10).take(6),
        today: today,
      );
      final absent = BioAgeActivity.fromDays([], today: today);
      expect(partial.reportedMinutes, 60);
      expect(partial.coveredDays, 6);
      expect(partial.missingDays, 1);
      expect(partial.minutesForScore, isNull);
      expect(result(partial).contributions, isNot(contains('activity')));
      expect(result(partial).lifeExpectancy, result(absent).lifeExpectancy);
    },
  );

  test(
    'invalid minutes may use steps; invalid inputs never imply zero activity',
    () {
      final input = week(steps: 6000);
      for (var i = 0; i < 3; i++) {
        input[i] = BioAgeActivityDay(
          date: input[i].date,
          reportedMinutes: [-1.0, double.nan, double.infinity][i],
          steps: 6000,
        );
      }
      final estimated = BioAgeActivity.fromDays(input, today: today);
      expect(estimated.minutesForScore, 420);
      input[0] = BioAgeActivityDay(
        date: today,
        reportedMinutes: double.nan,
        steps: -1,
      );
      final incomplete = BioAgeActivity.fromDays(input, today: today);
      expect(incomplete.coveredDays, 6);
      expect(incomplete.minutesForScore, isNull);
    },
  );

  test('only the seven calendar dates ending today are counted', () {
    final activity = BioAgeActivity.fromDays([
      ...week(steps: 6000),
      BioAgeActivityDay(date: DateTime(2026, 10, 23, 23), reportedMinutes: 999),
      BioAgeActivityDay(date: DateTime(2026, 10, 31), reportedMinutes: 999),
    ], today: today);
    expect(activity.minutesForScore, 420);
    expect(activity.coveredDays, 7);
    expect(activity.reportedDays, 0);
  });

  test('duplicate daily snapshots cannot double count minutes or steps', () {
    final input = week(steps: 6000);
    final activity = BioAgeActivity.fromDays([
      ...input,
      ...input,
      BioAgeActivityDay(date: today, reportedMinutes: 20, steps: 6000),
      BioAgeActivityDay(date: today, reportedMinutes: 20, steps: 6000),
    ], today: today);
    expect(activity.reportedMinutes, 20);
    expect(activity.estimatedWalkingMinutes, 360);
    expect(activity.coveredDays, 7);
    expect(activity.minutesForScore, 380);
  });

  test(
    'a calendar week spanning a daylight-saving transition has seven dates',
    () {
      final end = DateTime(2026, 3, 30);
      final activity = BioAgeActivity.fromDays([
        for (var i = 0; i < 7; i++)
          BioAgeActivityDay(
            date: DateTime(2026, 3, 30 - i),
            reportedMinutes: 30,
          ),
      ], today: end);
      expect(activity.coveredDays, 7);
      expect(activity.minutesForScore, 210);
    },
  );

  test(
    'walking estimates improve continuously rather than stopping at 3000 steps',
    () {
      final low = BioAgeActivity.fromDays(week(steps: 3000), today: today);
      final high = BioAgeActivity.fromDays(week(steps: 10000), today: today);
      expect(
        result(high).contributions['activity'],
        lessThan(result(low).contributions['activity']!),
      );
      expect(
        result(high).lifeExpectancy,
        greaterThan(result(low).lifeExpectancy),
      );
      expect(result(high).activity.usesStepEstimate, isTrue);
    },
  );

  test(
    'reported minutes determine the factor even for low-step cycling days',
    () {
      final r = estimateBioAge(
        const BioAgePerson(
          sex: 'm',
          age: 45,
          vo2max: 52,
          dailySteps: 1000,
          weeklyActivityMinutes: 600,
        ),
      );
      expect(r.contributions['activity'], 0);
      expect(r.activity.usesStepEstimate, isFalse);
    },
  );

  test('unknown activity never fabricates a default weekly total', () {
    final r = estimateBioAge(const BioAgePerson(sex: 'm', age: 45, vo2max: 52));
    expect(r.activity.coveredDays, 0);
    expect(r.contributions, isNot(contains('activity')));
  });

  test('step fallback does not also inflate the estimated VO2max', () {
    final activity = BioAgeActivity.fromDays(week(steps: 10000), today: today);
    final baseline = estimateBioAge(const BioAgePerson(sex: 'm', age: 45));
    final withSteps = estimateBioAge(
      BioAgePerson(sex: 'm', age: 45, activity: activity),
    );
    expect(withSteps.vo2max, baseline.vo2max);
    expect(withSteps.fitnessAge, baseline.fitnessAge);
    expect(withSteps.contributions['vo2max'], baseline.contributions['vo2max']);
    expect(withSteps.contributions, contains('activity'));
  });
}
