import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/services/activity_power_estimator.dart';

void main() {
  test(
    'finds best full twenty minute power rather than whole ride average',
    () {
      final rows = [
        for (var t = 0; t <= 2400; t += 10)
          {'d': t * 5, 'spd': 5, 'w': t <= 1200 ? 200 : 300},
      ];
      expect(best20MinutePower(jsonEncode(rows)), closeTo(300, .001));
    },
  );
  test('rejects short rides, missing power and malformed cache', () {
    expect(
      best20MinutePower(
        jsonEncode([
          for (var t = 0; t <= 1190; t += 10) {'d': t * 5, 'spd': 5, 'w': 300},
        ]),
      ),
      isNull,
    );
    expect(
      best20MinutePower(
        jsonEncode([
          for (var t = 0; t <= 2400; t += 10)
            {'d': t * 5, 'spd': 5, 'w': t == 900 || t == 1800 ? null : 300},
        ]),
      ),
      isNull,
    );
    expect(best20MinutePower('broken'), isNull);
  });
}
