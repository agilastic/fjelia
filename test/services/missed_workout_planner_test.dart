import 'package:fjelia/services/missed_workout_planner.dart';
import 'package:fjelia/services/season/goal_set.dart' show DayLoad;
import 'package:flutter_test/flutter_test.dart';

import '../providers/upcoming_done_test.dart' show session;

void main() {
  // Monday.
  final today = DateTime(2026, 11, 2);
  DateTime day(int i) => DateTime(today.year, today.month, today.day + i);
  final longRun = session('missed', today, minutes: 90);
  final easy = session(
    'easy',
    today,
    minutes: 40,
  ).copyWith(sessionType: 'recovery', primaryZone: 1);

  group('weightOf', () {
    test('long, key and high-zone sessions are hard', () {
      expect(weightOf(longRun), SessionWeight.hard);
      expect(
        weightOf(easy.copyWith(sessionType: 'easy', primaryZone: 4)),
        SessionWeight.hard,
      );
    });
    test('recovery and zone 1-2 sessions are easy', () {
      expect(weightOf(easy), SessionWeight.easy);
    });
  });

  group('suggestMove', () {
    test('tomorrow wins when the next days are free', () {
      final s = suggestMove(missed: longRun, upcoming: const [], today: today);
      expect(s.candidates.map((c) => c.date), [day(1), day(2), day(3)]);
      expect(s.recommendDrop, isFalse);
    });

    test('the window follows the setting', () {
      final s = suggestMove(
        missed: longRun,
        upcoming: const [],
        today: today,
        daysAhead: 5,
      );
      expect(s.candidates, hasLength(5));
    });

    test('a hard session never lands on a day with another hard one', () {
      final s = suggestMove(
        missed: longRun,
        upcoming: [session('tue', day(1), minutes: 60)],
        today: today,
        maxPerDay: 2,
      );
      expect(s.candidates.map((c) => c.date), isNot(contains(day(1))));
    });

    test('full days, race days and taper days are left out', () {
      final s = suggestMove(
        missed: longRun,
        upcoming: [easy.copyWith(id: 'wed', sessionDate: day(2))],
        today: today,
        dayLoad: (d) => d == day(1)
            ? DayLoad.blocked
            : d == day(3)
            ? DayLoad.easyOnly
            : DayLoad.free,
      );
      expect(s.candidates, isEmpty);
    });

    test('next to a hard day and on a rest day costs points', () {
      final s = suggestMove(
        missed: longRun,
        upcoming: [session('thu', day(3), minutes: 60)],
        today: today,
        restWeekdays: const [DateTime.tuesday],
      );
      final tue = s.candidates.firstWhere((c) => c.date == day(1));
      final wed = s.candidates.firstWhere((c) => c.date == day(2));
      expect(tue.notes, contains(MoveNote.restDay));
      expect(wed.notes, contains(MoveNote.nextToHard));
      expect(s.best!.date, isNot(day(2)));
    });

    test('rain moves an outdoor run indoors', () {
      final s = suggestMove(
        missed: longRun,
        upcoming: const [],
        today: today,
        rainyOn: (d) => d == day(1),
      );
      final tue = s.candidates.firstWhere((c) => c.date == day(1));
      expect(tue.indoor, isTrue);
      expect(tue.notes, contains(MoveNote.indoorForRain));
    });

    test('rain does not change a swim or an indoor session', () {
      for (final m in [
        longRun.copyWith(sport: 'swimming'),
        longRun.copyWith(indoor: true),
      ]) {
        final s = suggestMove(
          missed: m,
          upcoming: const [],
          today: today,
          rainyOn: (_) => true,
        );
        expect(s.candidates.every((c) => !c.indoor), isTrue);
      }
    });

    test('an easy session is best dropped', () {
      final s = suggestMove(missed: easy, upcoming: const [], today: today);
      expect(s.recommendDrop, isTrue);
      expect(s.candidates, isNotEmpty);
    });
  });

  test('a wet day has 2 mm in daylight or a likely shower', () {
    final d = day(1);
    ({DateTime time, double mm, int? probability}) h(
      int hour,
      double mm, [
      int? p,
    ]) =>
        (time: DateTime(d.year, d.month, d.day, hour), mm: mm, probability: p);
    expect(isRainyDay([h(9, 1), h(10, 1.2)], d), isTrue);
    expect(isRainyDay([h(3, 5)], d), isFalse);
    expect(isRainyDay([h(15, 0.1, 80)], d), isTrue);
    expect(isRainyDay([h(15, 0.4, 40)], d), isFalse);
  });
}
