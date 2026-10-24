import 'dart:convert';

import 'package:fjelia/models/device_hr_zones.dart';
import 'package:fjelia/services/polar_service.dart';
import 'package:fjelia/services/hr_zone_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('%LTHR floors, scaling and upper bounds', () {
    expect(lthrZoneFloors(170), [111, 145, 153, 162, 170]);
    expect(lthrZoneFloors(160, cycling: true), [96, 130, 144, 150, 160]);
    // Keep the athlete's own percentages when the threshold moves.
    expect(scaleZoneFloors([120, 150, 160, 170, 180], from: 170, to: 175), [
      124,
      154,
      165,
      175,
      185,
    ]);
    expect(zoneUpperBounds([111, 145, 153, 162, 170]), [145, 153, 162, 170]);
    expect(zoneUpperBounds([145, 153, 162, 170]), [145, 153, 162, 170]);
  });

  test('time in zone from samples is time-weighted', () {
    final floors = [100, 130, 150, 160, 170];
    final t0 = DateTime(2026, 10, 1).millisecondsSinceEpoch;
    // 60 s in Z2 (140 bpm), then 30 s in Z5 (175 bpm), 1 s sampling.
    final samples = [
      for (var i = 0; i <= 90; i++)
        {'hr': i <= 60 ? 140 : 175, 't': t0 + i * 1000},
    ];
    final zones = zonePercentFromSamples(jsonEncode(samples), floors)!;
    expect(zones['zone2']!, closeTo(66.7, 1));
    expect(zones['zone5']!, closeTo(33.3, 1));
    expect(zonePercentFromSamples('[]', floors), isNull);
  });

  test('parses Garmin zone settings per sport', () {
    final s = DeviceHrZones.fromGarminJson({
      'sport': 'RUNNING',
      'trainingMethod': 'LACTATE_THRESHOLD',
      'zone1Floor': 120,
      'zone2Floor': 145,
      'zone3Floor': 155,
      'zone4Floor': 163,
      'zone5Floor': 171,
      'lactateThresholdHeartRateUsed': 171,
      'maxHeartRateUsed': 188,
    })!;
    expect(s.isLthrBased, isTrue);
    expect(s.floors, [120, 145, 155, 163, 171]);
    expect(s.lthr, 171);
    expect(DeviceHrZones.fromGarminJson({'sport': 'DEFAULT'}), isNull);
  });

  test('maps Polar exercise zones to floors and time in zone', () {
    final z = PolarService.parseHeartRateZones([
      for (var i = 0; i < 5; i++)
        {
          'index': i,
          'lower_limit': 100 + i * 15,
          'upper_limit': 114 + i * 15,
          'in_zone': i == 1 ? 'PT30M' : 'PT10M',
        },
    ])!;
    expect(z.floors, [100, 115, 130, 145, 160]);
    expect(z.upper, 174);
    expect(z.percent['zone2']!, closeTo(42.9, 0.1));
    expect(PolarService.parseHeartRateZones(const []), isNull);
  });
}
