import 'package:fjelia/utils/target_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseTargetTime', () {
    test('hours, minutes and seconds', () {
      expect(parseTargetTime('3:30:00'), 12600);
      expect(parseTargetTime('1:42:10'), 6130);
      expect(parseTargetTime(' 3:30:00 '), 12600);
      expect(parseTargetTime('11:35:00', distanceKm: 70), 41700);
    });

    test('words and plain minutes', () {
      expect(parseTargetTime('3h30'), 12600);
      expect(parseTargetTime('3h 30m'), 12600);
      expect(parseTargetTime('3h'), 10800);
      expect(parseTargetTime('210'), 12600);
    });

    test('two parts depend on the race', () {
      // A marathon: hours and minutes.
      expect(parseTargetTime('3:30', distanceKm: 42.2), 12600);
      // A 5 km: minutes and seconds, as nobody runs it in 25 hours.
      expect(parseTargetTime('25:00', distanceKm: 5), 1500);
      expect(parseTargetTime('19:45', distanceKm: 5), 1185);
      // A 10 km in 45:00 stays minutes, a half marathon 1:45 hours.
      expect(parseTargetTime('45:00', distanceKm: 10), 2700);
      expect(parseTargetTime('1:45', distanceKm: 21.1), 6300);
      // Without a distance two parts are hours and minutes.
      expect(parseTargetTime('3:30'), 12600);
    });

    test('rejects what is not a time', () {
      for (final bad in [
        null,
        '',
        'abc',
        '3:75',
        '3:30:75',
        '0',
        '0:00',
        '1:2:3:4',
        '-3:00',
      ]) {
        expect(parseTargetTime(bad), isNull, reason: '$bad');
      }
    });

    test('rejects a time nobody could hold over the distance', () {
      // A marathon in 40 minutes, or in 600 hours.
      expect(
        parseTargetTime('0:40:00', distanceKm: 42.2, sport: 'running'),
        isNull,
      );
      expect(parseTargetTime('600:00:00', distanceKm: 42.2), isNull);
      // The same time is a ride's pace, not a run's.
      expect(
        parseTargetTime('1:00:00', distanceKm: 42.2, sport: 'cycling_road'),
        3600,
      );
      expect(
        parseTargetTime('1:00:00', distanceKm: 42.2, sport: 'running'),
        isNull,
      );
    });
  });

  test('formatting', () {
    expect(formatTargetTime(12600), '3:30:00');
    expect(formatTargetTime(2700), '45:00');
    expect(formatTargetTime(6130), '1:42:10');
    expect(formatPace(299.4), '4:59/km');
    expect(formatPace(300), '5:00/km');
  });
}
