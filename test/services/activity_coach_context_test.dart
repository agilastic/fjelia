import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/activity_coach_context.dart';
import 'package:fjelia/services/hrv/hrv_training_service.dart';
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

void hrvTests() {
  final start = DateTime(2026, 10, 18, 8);
  final end = DateTime(2026, 10, 18, 13, 48);

  group('hrvAroundLine', () {
    test('overnight values with the change worked out, no spot readings', () {
      final line = hrvAroundLine(
        start: start,
        end: end,
        preNight: 44,
        preDate: DateTime(2026, 10, 18),
        weeklyAverage: 46,
        postNight: 38,
        postDate: DateTime(2026, 10, 19),
      );
      expect(
        line,
        '[HRV:AroundActivity,PreNight:44ms(2026-10-18),PostNight:38ms(2026-10-19),'
        'NightChange:-6ms(-14%),WeeklyAvg:46ms,'
        'Note:NightValuesAreWatchMeasuredNotComparableToSpotRMSSD]',
      );
      expect(line, isNot(contains('SpotBefore')));
    });

    test('a missing night after is left out', () {
      final line = hrvAroundLine(
        start: start,
        end: end,
        preNight: 44,
        preDate: DateTime(2026, 10, 18),
      );
      expect(line, contains('PreNight:44ms'));
      expect(line, isNot(contains('PostNight')));
      expect(line, isNot(contains('NightChange')));
    });

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

    Future<void> reading(
      DateTime at,
      String context, {
      double rmssd = 60,
      String posture = 'seated',
    }) => db
        .into(db.spotHrvMeasurements)
        .insert(
          SpotHrvMeasurementsCompanion.insert(
            startedAt: at,
            context: context,
            posture: posture,
            durationSeconds: 300,
            settleSeconds: 60,
            deviceId: 'h10',
            deviceName: 'Polar H10',
            rmssdMs: rmssd,
            sdnnMs: 65,
            meanHr: 58,
            acceptedIntervals: 280,
            totalIntervals: 290,
            coverage: .97,
            rrJson: '[]',
            samplingEndedAt: Value(at.add(const Duration(seconds: 300))),
            qualityState: const Value('usable'),
          ),
        );

    Future<ActivityRecord> ride({
      DateTime? at,
      int seconds = 2 * 3600,
      String type = 'cycling',
    }) async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'ride',
              name: 'Ride',
              type: type,
              startDate: at ?? DateTime(2026, 10, 18, 8),
              durationSeconds: seconds,
              source: const Value('garmin_api'),
            ),
          );
      return (await db.select(db.activityRecords).get()).single;
    }

    test('nights and the pair come from the shared assessment', () async {
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
      final a = await ride();
      await reading(DateTime(2026, 10, 18, 7, 10), 'beforeTraining');
      await reading(DateTime(2026, 10, 18, 10, 31), 'afterTraining', rmssd: 45);
      final toon = await ActivityCoachContextBuilder(db).build(a);
      final lines = toon.split('\n');
      final nights = lines.firstWhere(
        (l) => l.startsWith('[HRV:AroundActivity'),
      );
      expect(nights, contains('PreNight:44ms(2026-10-18)'));
      expect(nights, contains('PostNight:38ms(2026-10-19)'));
      expect(nights, isNot(contains('SpotBefore')));
      final pair = lines.firstWhere((l) => l.startsWith('[HRV:Pair'));
      expect(pair, contains('Assoc:unambiguous'));
      expect(pair, contains('Comparable:yes'));
      expect(pair, contains('Change:-15.0ms/-25.0%/ln-0.2877'));
      expect(pair, contains('/after31min'));
      expect(pair, contains('Timing:inTargetBand'));
      expect(pair, contains('Purpose:retrospective'));
      expect(pair, contains('History:n=0/need8/insufficientData'));
      expect(
        pair,
        contains('Unknown:RPE|Heat|Fuelling|FollowUpNight|PersonalRange'),
      );
      expect(pair, isNot(contains('Ride')));
    });

    test('HRV-T062 a limitation survives into the line', () async {
      final a = await ride();
      await reading(DateTime(2026, 10, 18, 7, 10), 'beforeTraining');
      await reading(
        DateTime(2026, 10, 18, 10, 31),
        'afterTraining',
        posture: 'supine',
      );
      final pair = (await ActivityCoachContextBuilder(
        db,
      ).build(a)).split('\n').firstWhere((l) => l.startsWith('[HRV:Pair'));
      expect(pair, contains('Comparable:no'));
      expect(pair, contains('Change:none'));
      expect(pair, contains('Limits:postureMismatch'));
    });

    test('HRV-T003 a reading starting before the end is not a post', () async {
      final a = await ride();
      await reading(DateTime(2026, 10, 18, 7, 10), 'beforeTraining');
      // Starts ten minutes before the workout ended.
      await reading(DateTime(2026, 10, 18, 9, 50), 'afterTraining');
      final toon = await ActivityCoachContextBuilder(db).build(a);
      final pair = toon
          .split('\n')
          .firstWhere((l) => l.startsWith('[HRV:Pair'));
      expect(pair, contains('Post:none'));
      expect(pair, contains('missingPost'));
      expect(toon, contains('[HRV:Unassigned,Count:1'));
    });

    test('HRV-T063 missing RPE, follow-up and history stay unknown', () async {
      final a = await ride();
      await reading(DateTime(2026, 10, 18, 7, 10), 'beforeTraining');
      final pair = (await ActivityCoachContextBuilder(
        db,
      ).build(a)).split('\n').firstWhere((l) => l.startsWith('[HRV:Pair'));
      expect(pair, contains('Post:none'));
      expect(pair, contains('Unknown:RPE'));
      expect(pair, isNot(contains('Rpe:')));
    });

    test('a known RPE is given and no longer unknown', () async {
      final a = await ride();
      await reading(DateTime(2026, 10, 18, 7, 10), 'beforeTraining');
      final service = HrvTrainingService(db);
      await service.reconcile();
      final id = (await service.episodeIdOfActivity('ride'))!;
      await service.recordFeedback(id, rpe: 7);
      final pair = (await ActivityCoachContextBuilder(
        db,
      ).build(a)).split('\n').firstWhere((l) => l.startsWith('[HRV:Pair'));
      expect(pair, contains('Rpe:7'));
      expect(pair, isNot(contains('Unknown:RPE')));
    });

    test(
      'HRV-T039 a workout over midnight takes the night after its end',
      () async {
        await db.upsertHrv(
          HrvRecordsCompanion(
            date: Value(DateTime(2026, 10, 19)),
            hrvLastNight: const Value(50),
            source: const Value('garmin_api'),
          ),
        );
        await db.upsertHrv(
          HrvRecordsCompanion(
            date: Value(DateTime(2026, 10, 20)),
            hrvLastNight: const Value(41),
            source: const Value('garmin_api'),
          ),
        );
        // 23:00 to 01:00: the night of the 19th started before it ended.
        final a = await ride(at: DateTime(2026, 10, 18, 23), seconds: 7200);
        final toon = await ActivityCoachContextBuilder(db).build(a);
        expect(toon, isNot(contains('PostNight:50ms')));
        final nights = toon
            .split('\n')
            .firstWhere((l) => l.startsWith('[HRV:AroundActivity'));
        expect(nights, contains('PostNight:41ms(2026-10-20)'));
      },
    );

    test('says so when no HRV was recorded', () async {
      final run = await ride(type: 'running');
      final toon = await ActivityCoachContextBuilder(db).build(run);
      expect(toon, contains('[HRV:AroundActivity,Unavailable]'));
      expect(toon, isNot(contains('[HRV:Pair')));
    });
  });
}
