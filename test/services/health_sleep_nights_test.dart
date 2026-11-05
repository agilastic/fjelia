import 'package:fjelia/services/health_connect_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

void main() {
  HealthSleepSample s(
    HealthDataType type,
    int h0,
    int m0,
    int h1,
    int m1,
    String source,
  ) {
    DateTime at(int h, int m) =>
        h >= 18 ? DateTime(2026, 11, 4, h, m) : DateTime(2026, 11, 5, h, m);
    return (type: type, from: at(h0, m0), to: at(h1, m1), source: source);
  }

  final night = [
    // COROS: stages on both sides of midnight.
    s(HealthDataType.SLEEP_LIGHT, 23, 27, 23, 36, 'COROS'),
    s(HealthDataType.SLEEP_DEEP, 23, 36, 0, 15, 'COROS'),
    s(HealthDataType.SLEEP_REM, 1, 18, 2, 1, 'COROS'),
    // Garmin Connect, the same night.
    s(HealthDataType.SLEEP_DEEP, 23, 35, 0, 15, 'Connect'),
    s(HealthDataType.SLEEP_LIGHT, 0, 15, 6, 40, 'Connect'),
    // Polar Flow.
    s(HealthDataType.SLEEP_DEEP, 23, 40, 23, 58, 'Polar Flow'),
    // The phone: only "asleep".
    s(HealthDataType.SLEEP_ASLEEP, 23, 20, 6, 50, 'iPhone'),
  ];

  test('a night is filed under its wake-up day, not split at midnight', () {
    final nights = healthSleepNights(night, const ['coros', 'garmin_api']);
    expect(nights.keys, [DateTime(2026, 11, 5)]);
    expect(nights.values.single.samples, hasLength(3));
  });

  test('one source per night, following the sleep priority', () {
    final coros = healthSleepNights(night, const ['coros', 'garmin_api']);
    expect(coros.values.single.source, 'COROS');
    expect(coros.values.single.samples.map((x) => x.source).toSet(), {'COROS'});
    final garmin = healthSleepNights(night, const ['garmin_api', 'coros']);
    expect(garmin.values.single.source, 'Connect');
  });

  test('stages win over "asleep", then the most staged sleep', () {
    final nights = healthSleepNights(night, const ['health_connect']);
    // None is in the priority except the phone, which has no stages.
    expect(nights.values.single.source, 'Connect');
  });

  test('app names map to Fjelia sources', () {
    expect(healthSleepSourceKey('COROS'), 'coros');
    expect(healthSleepSourceKey('Connect'), 'garmin_api');
    expect(healthSleepSourceKey('Garmin Connect'), 'garmin_api');
    expect(healthSleepSourceKey('Polar Flow'), 'polar');
    expect(healthSleepSourceKey('Alex’s Apple Watch'), 'health_connect');
  });
}
