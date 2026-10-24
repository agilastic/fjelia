import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/services/tcx_parser.dart';

const _tcx = '''<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
 <Activities>
  <Activity Sport="Running">
   <Id>2026-08-19T06:30:00.000Z</Id>
   <Lap StartTime="2026-08-19T06:30:00.000Z">
    <TotalTimeSeconds>1800.0</TotalTimeSeconds>
    <DistanceMeters>5000.0</DistanceMeters>
    <Calories>400</Calories>
    <AverageHeartRateBpm><Value>140</Value></AverageHeartRateBpm>
    <MaximumHeartRateBpm><Value>165</Value></MaximumHeartRateBpm>
    <Track>
     <Trackpoint><Time>2026-08-19T06:30:00.000Z</Time>
      <Position><LatitudeDegrees>52.1</LatitudeDegrees><LongitudeDegrees>9.7</LongitudeDegrees></Position>
      <HeartRateBpm><Value>120</Value></HeartRateBpm></Trackpoint>
     <Trackpoint><Time>2026-08-19T06:30:05.000Z</Time>
      <Position><LatitudeDegrees>52.1001</LatitudeDegrees><LongitudeDegrees>9.7001</LongitudeDegrees></Position>
      <HeartRateBpm><Value>130</Value></HeartRateBpm></Trackpoint>
    </Track>
   </Lap>
   <Lap StartTime="2026-08-19T07:00:00.000Z">
    <TotalTimeSeconds>600.0</TotalTimeSeconds>
    <DistanceMeters>1500.0</DistanceMeters>
    <Calories>130</Calories>
    <AverageHeartRateBpm><Value>160</Value></AverageHeartRateBpm>
    <MaximumHeartRateBpm><Value>172</Value></MaximumHeartRateBpm>
   </Lap>
  </Activity>
 </Activities>
</TrainingCenterDatabase>''';

void main() {
  test('sums laps and weights the average heart rate by time', () {
    final s = parseTcx(_tcx)!;
    expect(s.sport, 'Running');
    expect(s.start, DateTime.utc(2026, 8, 19, 6, 30));
    expect(s.durationSeconds, 2400);
    expect(s.distanceMeters, 6500);
    expect(s.calories, 530);
    // (140*1800 + 160*600) / 2400 = 145
    expect(s.avgHeartRate, closeTo(145, 0.01));
    expect(s.maxHeartRate, 172);
  });

  test('collects heart-rate samples and the route', () {
    final s = parseTcx(_tcx, source: 'polar')!;
    expect(s.heartRates, hasLength(2));
    expect(s.heartRates.first.bpm, 120);
    expect(s.heartRates.first.source, 'polar');
    expect(s.route, [
      {'lat': 52.1, 'lng': 9.7},
      {'lat': 52.1001, 'lng': 9.7001},
    ]);
  });

  test('returns null for documents without an activity', () {
    expect(parseTcx('<foo/>'), isNull);
    expect(parseTcx('<Activity Sport="Other"><Lap></Lap></Activity>'), isNull);
  });
}
