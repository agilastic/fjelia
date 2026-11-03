import 'package:fjelia/services/fit_activity_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/coros_fit_fixture.dart';

void main() {
  test('compressed-timestamp records are all read, with their times', () {
    final fit = parseFitActivity(corosStyleFit())!;
    expect(fit.samples, hasLength(121));
    expect(fit.route, hasLength(121));
    final first = fit.samples.first['t']!, last = fit.samples.last['t']!;
    expect((last - first) / 1000, 120);
    expect(fit.maxHeartRate, 99);
    expect(fit.sport, 'walking');
  });
}
