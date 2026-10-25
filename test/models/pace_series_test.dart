import 'package:fjelia/models/pace_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 3 m/s is 5:33 min/km.
  double pace(double mps) => 1000 / mps / 60;

  test('standing still is a gap, not a 30 min/km spike', () {
    final out = chartPace([3, 3, 3, 0.4, 0.2, 0.3, 3, 3, 3]);
    expect(out.sublist(3, 6), [null, null, null]);
    expect(out.first, closeTo(pace(3), 1e-9));
    expect(out.whereType<double>().every((p) => p < stopPaceMinutes), isTrue);
  });

  test(
    'a very slow but moving pace (just under the stop limit) is a gap too',
    () {
      // 1 m/s is 16:40 min/km: slower than any running pace in a chart.
      final out = chartPace([3, 3, 1, 3, 3]);
      expect(out[2], isNull);
    },
  );

  test('a walking break stays visible', () {
    // 1.5 m/s is 11:07 min/km.
    final out = chartPace([1.5, 1.5, 1.5, 1.5, 1.5]);
    expect(out.every((p) => p != null && (p - pace(1.5)).abs() < 1e-9), isTrue);
  });

  test('a single GPS jump is smoothed away', () {
    final out = chartPace([3, 3, 3, 1.6, 3, 3, 3]);
    expect(out[3], closeTo(pace(3), 1e-9));
  });

  test('the median never reaches across a stop', () {
    final out = chartPace([2, 2, 0, 4, 4]);
    expect(out[1], closeTo(pace(2), 1e-9));
    expect(out[3], closeTo(pace(4), 1e-9));
  });

  test('missing and non-finite speeds are gaps', () {
    expect(chartPace([null, double.nan, double.infinity]), [null, null, null]);
  });

  test('speed leaves out standing still and keeps km/h', () {
    final out = chartSpeed([10, 10, 0.1, 10, 10]);
    expect(out[2], isNull);
    expect(out[0], closeTo(36, 1e-9));
  });

  test('the axis follows the bulk, not the outlier', () {
    final values = [for (var i = 0; i < 100; i++) 5.0 + (i % 10) / 10, 30.0];
    final (low, high) = robustRange(values);
    expect(high, lessThan(7));
    expect(low, greaterThan(4));
  });

  test('a flat series still gets a usable span', () {
    final (low, high) = robustRange([5, 5, 5], minSpan: 1);
    expect(high - low, greaterThanOrEqualTo(1));
    expect(robustRange(const []), (0, 1));
  });
}
