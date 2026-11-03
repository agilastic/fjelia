import 'package:fjelia/l10n/formats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planned durations: minutes up to an hour, then hours and minutes', () {
    expect(planDuration(45), '45 min');
    expect(planDuration(60), '60 min');
    expect(planDuration(75), '1 h 15 min');
    expect(planDuration(120), '2 h');
    expect(planDuration(150), '2 h 30 min');
  });
}
