import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
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
  hrvTests();
  test('the comparison with similar sessions is worked out in advance', () {
    final target = act(
      't',
      DateTime(2026, 10, 18, 8),
      type: 'cycling',
      minutes: 300,
      km: 100,
      hr: 130,
      load: 240,
    );
    final toon = ActivityCoachContextBuilder.buildFrom(target, [
      act(
        'a',
        DateTime(2026, 10, 10),
        type: 'cycling',
        minutes: 60,
        km: 25,
        hr: 125,
        load: 80,
      ),
      act(
        'b',
        DateTime(2026, 10, 14),
        type: 'cycling',
        minutes: 100,
        km: 40,
        hr: 135,
        load: 100,
      ),
      act('run', DateTime(2026, 10, 15), type: 'running'),
      target,
    ]);
    // Averages of the two other rides: 80 min, 32.5 km, load 90, heart rate 130.
    expect(
      toon,
      contains(
        '[Compare:ride,N:2,Min:300 vs 80 (3.8x),Km:100.0 vs 32.5 (3.1x),'
        'Load:240 vs 90 (2.7x),AvgHR:130 vs 130 (+0 bpm)]',
      ),
    );
  });

  test('no comparison without other sessions of the sport', () {
    final target = act('t', DateTime(2026, 10, 18, 8), type: 'cycling');
    final toon = ActivityCoachContextBuilder.buildFrom(target, [
      act('run', DateTime(2026, 10, 15), type: 'running'),
      target,
    ]);
    expect(toon, isNot(contains('[Compare:')));
  });

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

    expect(
      toon,
      contains(
        '[Activity:2026-10-18 Sun,Sport:run,Min:60,Km:12.0,'
        'Pace:5:00/km,AvgHR:145',
      ),
    );
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

SpotHrvMeasurement spot(
  DateTime at,
  double rmssd, {
  String posture = 'seated',
  String context = 'beforeTraining',
  int seconds = 300,
  int? minutesAfter,
}) => SpotHrvMeasurement(
  id: 0,
  startedAt: at,
  context: context,
  posture: posture,
  durationSeconds: seconds,
  settleSeconds: 60,
  deviceId: 'h10',
  deviceName: 'Polar H10',
  rmssdMs: rmssd,
  sdnnMs: rmssd + 5,
  meanHr: 60,
  acceptedIntervals: 280,
  totalIntervals: 290,
  coverage: .97,
  rrJson: '[]',
  minutesAfterTraining: minutesAfter,
);

void hrvTests() {
  final start = DateTime(2026, 10, 18, 8);
  final end = DateTime(2026, 10, 18, 13, 48);

  group('hrvAroundLine', () {
    test('nights and spot readings with the changes worked out', () {
      final line = hrvAroundLine(
        start: start,
        end: end,
        preNight: 44,
        preDate: DateTime(2026, 10, 18),
        weeklyAverage: 46,
        postNight: 38,
        postDate: DateTime(2026, 10, 19),
        spots: [
          spot(DateTime(2026, 10, 18, 7, 10), 60),
          spot(
            DateTime(2026, 10, 18, 14, 15),
            45,
            context: 'afterTraining',
            minutesAfter: 27,
          ),
        ],
      );
      expect(
        line,
        '[HRV:AroundActivity,PreNight:44ms(2026-10-18),PostNight:38ms(2026-10-19),'
        'NightChange:-6ms(-14%),WeeklyAvg:46ms,SpotBefore:60ms(07:10,seated,5min),'
        'SpotAfter:45ms(14:15,seated,5min,27min after training),'
        'SpotChange:-15ms(-25%),Note:MethodsDiffer]',
      );
    });

    test(
      'picks the reading closest before the start and the first after the end',
      () {
        final line = hrvAroundLine(
          start: start,
          end: end,
          spots: [
            spot(DateTime(2026, 10, 18, 4), 50, posture: 'supine'),
            spot(DateTime(2026, 10, 18, 7), 55),
            spot(DateTime(2026, 10, 18, 14), 40, context: 'afterTraining'),
            spot(DateTime(2026, 10, 18, 18), 48, context: 'afterTraining'),
          ],
        );
        expect(line, contains('SpotBefore:55ms(07:00,seated,5min)'));
        expect(line, contains('SpotAfter:40ms(14:00,seated,5min)'));
        expect(line, contains('SpotChange:-15ms(-27%)'));
        expect(line, isNot(contains('PreNight')));
      },
    );

    test(
      'a lying reading is labelled, and a missing night after is left out',
      () {
        final line = hrvAroundLine(
          start: start,
          end: end,
          preNight: 44,
          preDate: DateTime(2026, 10, 18),
          spots: [spot(DateTime(2026, 10, 18, 7), 70, posture: 'supine')],
        );
        expect(line, contains('SpotBefore:70ms(07:00,lying,5min)'));
        expect(line, contains('PreNight:44ms'));
        expect(line, isNot(contains('PostNight')));
        expect(line, isNot(contains('NightChange')));
        expect(line, isNot(contains('SpotChange')));
      },
    );

    test('nothing recorded is stated, never guessed', () {
      expect(
        hrvAroundLine(start: start, end: end),
        '[HRV:AroundActivity,Unavailable]',
      );
    });
  });

  group('the activity chat context', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('includes the HRV around the activity when it was recorded', () async {
      await db.upsertHrv(
        HrvRecordsCompanion(
          date: Value(DateTime(2026, 10, 18)),
          hrvLastNight: const Value(44),
          hrvWeeklyAvg: const Value(46),
          source: const Value('garmin_api'),
        ),
      );
      await db.upsertHrv(
        HrvRecordsCompanion(
          date: Value(DateTime(2026, 10, 19)),
          hrvLastNight: const Value(38),
          source: const Value('garmin_api'),
        ),
      );
      await db
          .into(db.spotHrvMeasurements)
          .insert(
            SpotHrvMeasurementsCompanion.insert(
              startedAt: DateTime(2026, 10, 18, 7, 10),
              context: 'beforeTraining',
              posture: 'seated',
              durationSeconds: 300,
              settleSeconds: 60,
              deviceId: 'h10',
              deviceName: 'Polar H10',
              rmssdMs: 60,
              sdnnMs: 65,
              meanHr: 58,
              acceptedIntervals: 280,
              totalIntervals: 290,
              coverage: .97,
              rrJson: '[]',
            ),
          );
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'ride',
              name: 'Ride',
              type: 'cycling',
              startDate: DateTime(2026, 10, 18, 8),
              durationSeconds: 5 * 3600,
            ),
          );
      final ride = (await db.select(db.activityRecords).get()).single;
      final toon = await ActivityCoachContextBuilder(db).build(ride);
      final line = toon.split('\n').firstWhere((l) => l.startsWith('[HRV:'));
      expect(line, contains('PreNight:44ms(2026-10-18)'));
      expect(line, contains('PostNight:38ms(2026-10-19)'));
      expect(line, contains('SpotBefore:60ms(07:10,seated,5min)'));
      expect(line, isNot(contains('SpotAfter')));
    });

    test('says so when no HRV was recorded', () async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'run',
              name: 'Run',
              type: 'running',
              startDate: DateTime(2026, 10, 18, 8),
              durationSeconds: 3000,
            ),
          );
      final run = (await db.select(db.activityRecords).get()).single;
      final toon = await ActivityCoachContextBuilder(db).build(run);
      expect(toon, contains('[HRV:AroundActivity,Unavailable]'));
    });
  });
}
