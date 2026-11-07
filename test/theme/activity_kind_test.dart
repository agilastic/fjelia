import 'package:fjelia/theme/activity_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('virtual and Strava rides are cycling, strides are not', () {
    expect(activityKind('virtual_ride'), ActivityKind.cycling);
    expect(activityKind('Ride'), ActivityKind.cycling);
    expect(activityKind('EBikeRide'), ActivityKind.cycling);
    expect(activityKind('stride'), isNot(ActivityKind.cycling));
  });
}
