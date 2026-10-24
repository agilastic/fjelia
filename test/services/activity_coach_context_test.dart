import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/activity_coach_context.dart';
import 'package:flutter_test/flutter_test.dart';

ActivityRecord act(
  String id,
  DateTime at, {
  String type = 'running',
  int minutes = 50,
  double? km = 10,
  double? hr = 145,
  double load = 60,
}) => ActivityRecord(
  id: 0,
  activityId: id,
  name: 'Morgenlauf am Fluss $id',
  type: type,
  startDate: at,
  durationSeconds: minutes * 60,
  distanceMeters: km == null ? null : km * 1000,
  avgHeartRate: hr,
  trainingLoad: load,
  source: 'garmin',
);

void main() {
  test('activity context covers activity, last 30 days and year', () {
    final target = act('t', DateTime(2026, 10, 18, 8), minutes: 60, km: 12);
    final all = [
      act('a', DateTime(2026, 10, 10)),
      act('b', DateTime(2026, 10, 14), type: 'cycling', km: 30, minutes: 75),
      act('c', DateTime(2026, 9, 1)), // outside the 30-day window
      act('d', DateTime(2026, 2, 3), type: 'strength', km: null),
      act('e', DateTime(2025, 6, 1)), // last year, before Oct 18
      act('f', DateTime(2025, 11, 1)), // last year, after Oct 18
      target,
    ];
    final toon = ActivityCoachContextBuilder.buildFrom(target, all);

    expect(toon, contains('[Activity:2026-10-18 Sun,Sport:run,Min:60,Km:12.0,'
        'Pace:5:00/km,AvgHR:145'));
    expect(toon, contains('[Last30d:2026-09-19..2026-10-18,Sessions:3,'));
    expect(toon, contains('[Last30d:Sports:run 2x'));
    expect(toon, contains('ride 1x'));
    expect(toon, contains('[Similar30d:run,N:1,AvgMin:50,AvgKm:10.0'));
    expect(toon, contains('[Year:2026:ToDate(10/18),Sessions:5,'));
    expect(toon, contains('[Year:2025:ToDate(10/18),Sessions:1,'));
    expect(toon, contains('[Year:2026:Months:Jan 0h 0km;Feb 1h 0km;'));
    expect(toon, contains('strength 1x'));
    // Names never leave the device.
    expect(toon, isNot(contains('Morgenlauf')));
  });
}
