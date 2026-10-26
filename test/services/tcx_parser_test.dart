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

  test('reads prefixed trackpoints with attributes and TPX measurements', () {
    final session = parseTcx('''
<tcx:TrainingCenterDatabase xmlns:tcx="urn:tcx" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ns3="urn:extensions">
<tcx:Activity Sport="Running"><tcx:Id>2026-08-19T06:30:00Z</tcx:Id>
<tcx:Lap StartTime="2026-08-19T06:30:00Z"><tcx:TotalTimeSeconds>10</tcx:TotalTimeSeconds>
<tcx:Track>
<tcx:Trackpoint xsi:type="tcx:Trackpoint_t"><tcx:Time>2026-08-19T06:30:00Z</tcx:Time>
<tcx:AltitudeMeters>-12</tcx:AltitudeMeters><tcx:DistanceMeters>0</tcx:DistanceMeters>
<tcx:HeartRateBpm><tcx:Value>120</tcx:Value></tcx:HeartRateBpm>
<tcx:Cadence>0</tcx:Cadence><tcx:Extensions><ns3:TPX><ns3:Speed>0</ns3:Speed><ns3:Watts>0</ns3:Watts><ns3:RunCadence>79</ns3:RunCadence></ns3:TPX></tcx:Extensions>
</tcx:Trackpoint>
<tcx:Trackpoint xsi:type="tcx:Trackpoint_t"><tcx:Time>2026-08-19T06:30:10Z</tcx:Time>
<tcx:HeartRateBpm><tcx:Value>140</tcx:Value></tcx:HeartRateBpm>
<tcx:Extensions><ns3:TPX><ns3:Speed>2.5</ns3:Speed><ns3:Watts>250</ns3:Watts></ns3:TPX></tcx:Extensions>
</tcx:Trackpoint></tcx:Track></tcx:Lap></tcx:Activity>
</tcx:TrainingCenterDatabase>''')!;
    expect(session.heartRates, hasLength(2));
    expect(session.samples.first, containsPair('ele', -12));
    expect(session.samples.first, containsPair('d', 0));
    expect(session.samples.first, containsPair('spd', 0));
    expect(session.samples.first, containsPair('w', 0));
    expect(session.samples.first, containsPair('cad', 79));
    expect(session.samples.last, containsPair('spd', 2.5));
    expect(session.samples.last, containsPair('w', 250));
    expect(session.samples.last.containsKey('d'), isFalse);
  });

  test('merges repeated lap boundaries without doubling HR samples', () {
    final xml = _tcx.replaceFirst(
      '<TotalTimeSeconds>600.0</TotalTimeSeconds>',
      '''<TotalTimeSeconds>600.0</TotalTimeSeconds><Track><Trackpoint>
<Time>2026-08-19T06:30:05.000Z</Time><AltitudeMeters>30</AltitudeMeters>
</Trackpoint></Track>''',
    );
    final session = parseTcx(xml)!;
    expect(session.heartRates, hasLength(2));
    expect(session.samples.last['hr'], 130);
    expect(session.samples.last['ele'], 30);
  });

  test('malformed XML and non-finite readings do not enter activity data', () {
    expect(parseTcx('<Activity><broken>'), isNull);
    final session = parseTcx(_tcx.replaceFirst('5000.0', 'NaN'))!;
    expect(session.distanceMeters, 1500);
  });
}
