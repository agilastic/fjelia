import 'package:fjelia/services/apple_context_facts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sleep duration and shortfall keep their different meanings', () {
    final text = appleFactLine(
      '[Sleep:Latest:2026-10-29,Dur:7h,Need:8h,Score:70]',
    );
    expect(text, contains('slept 7h (duration; not missing sleep)'));
    expect(text, contains('Shortfall relative to that need: 1.0 h'));
    expect(
      appleFactLine('[Sleep:Latest:2026-10-29,Dur:7h,Need:na]'),
      contains('Sleep shortfall is unknown'),
    );
  });

  test('blood pressure is separate from the training phase', () {
    expect(
      appleFactLine('[BP:Latest:2026-10-29,Sys:139,Dia:77,HR:55]'),
      'Blood pressure on 2026-10-29: 139/77 mmHg. '
      'Blood pressure does not identify a training phase.',
    );
  });

  test('the complete race calendar survives as one compact block', () {
    final text = appleRaceCalendarFacts(const [
      '[RaceGoal:Sport:running,DistKm:42.2,Date:2027-08-08,Target:4:00:00,Priority:A]',
      '[RaceGoal:Sport:cycling_road,DistKm:200,Date:2027-03-20,Target:none,Priority:B]',
      '[RaceGoal:Sport:running,DistKm:21.1,Date:2027-10-10,Target:1:50:00,Priority:C]',
    ])!;
    expect(text, contains('3 listed goals'));
    expect(text, contains('2027-08-08 | A | running 42.2 km | target 4:00:00'));
    expect(text, contains('2027-03-20 | B | cycling road 200 km'));
    expect(text, contains('2027-10-10 | C | running 21.1 km'));
    expect(text, contains('primary goal is not the only goal'));
  });

  test(
    'two planned sessions are not described as alternatives or Garmin duplicates',
    () {
      final text = appleFactLine(
        '[TodayWorkout:Status:planned,Source:plan,SessionCount:2,GarminScheduled:2,PlanSessions:2]',
      );
      expect(text, contains('Today has 2 scheduled training sessions.'));
      expect(text, contains('not alternatives'));
      expect(text, contains('Garmin entries may be copies'));
    },
  );

  test('an activity becomes a sentence with the same figures', () {
    expect(
      appleFactLine(
        '[Activity:2026-10-22 Thu,Sport:run,Min:47,Km:8.4,Pace:5:34/km,AvgHR:138,MaxHR:171,Load:126,ElevM:159,AvgW:393,TE:3.4/0.4]',
      ),
      'Activity on 2026-10-22 Thu: run, 47 min, 8.4 km, pace 5:34/km, '
      'average heart rate 138 bpm, max heart rate 171 bpm, training load 126, '
      'elevation gain 159 m, average power 393 W, '
      'training effect 3.4/0.4 (aerobic/anaerobic).',
    );
  });

  test('an activity without distance or heart rate keeps only what exists', () {
    expect(
      appleFactLine('[Activity:2026-10-22 Thu,Sport:strength,Min:30,Load:20]'),
      'Activity on 2026-10-22 Thu: strength, 30 min, training load 20.',
    );
  });

  test('a planned session reads as a sentence', () {
    final text = appleFactLine(
      '[Session:Status:planned,Date:2026-10-23 Fri,Sport:cycling road,Type:endurance,Phase:base,Week:3,Duration:35min,TRIMP:26,Zone:Z2,Structure:8 min Warm-up>15 min Interval Z2]',
    );
    expect(
      text,
      startsWith(
        'Session (planned) 2026-10-23 Fri: cycling road, endurance, base phase, week 3, 35 min, TRIMP 26, main zone Z2.',
      ),
    );
    expect(text, contains('Structure: 8 min Warm-up, 15 min Interval Z2.'));
  });

  test('a completed session reports the zone percentages', () {
    final text = appleFactLine(
      '[Session:Status:completed,Date:2026-10-22 Thu,Sport:running,Duration:46min,HRZonePct:10/60/20/10/0]',
    );
    expect(
      text,
      contains('Time in heart-rate zones 1 to 5 (percent): 10, 60, 20, 10, 0.'),
    );
  });

  test('the previous activity and the gap rule', () {
    expect(
      appleFactLine(
        '[DataStatus:PreviousActivity:2026-08-23,DaysBefore:60,MissingRecord:Unknown]',
      ),
      'Previous activity: 2026-08-23, 60 days before this one. '
      'A missing record means unknown, not rest.',
    );
    expect(
      appleFactLine(
        '[DataStatus:PreviousActivity:NoneInLoadedHistory,MissingRecord:Unknown]',
      ),
      startsWith('No earlier activity in the loaded history.'),
    );
  });

  test('the daily status lists the newest records and the gaps', () {
    final text = appleFactLine(
      '[DataStatus:Activities(Last:2026-10-22,DaysAgo:2,ActiveDays28:3/28,LongestGap:16d),HRV(Last:2026-10-24,DaysAgo:0,Days28:10/28),Sleep(None),Gaps:Sleep none,MissingRecord:Unknown]',
    );
    expect(
      text,
      startsWith(
        'Newest records: Activities 2026-10-22 (2 days ago), HRV 2026-10-24 (0 days ago), Sleep none.',
      ),
    );
    expect(text, contains('Gaps: Sleep none.'));
    expect(
      text,
      contains('A missing record means unknown, not rest or no training.'),
    );
  });

  test('similar sessions and the last 30 days', () {
    expect(
      appleFactLine(
        '[Similar30d:run,N:14,AvgMin:53,AvgKm:8.0,AvgHR:140,AvgLoad:101,Pace:6:24/km]',
      ),
      'Other run sessions in the last 30 days: 14, on average 53 min, 8.0 km, '
      'heart rate 140 bpm, load 101, pace 6:24/km.',
    );
    expect(
      appleFactLine(
        '[Last30d:2026-09-23..2026-10-22,Sessions:32,ActiveDays:20,H:45.6,Km:651,Load:2747]',
      ),
      'Last 30 days (2026-09-23 to 2026-10-22): 32 sessions, on 20 days, '
      '45.6 h, 651 km, load 2747.',
    );
    expect(
      appleFactLine('[Last30d:Weeks(oldest..newest):12.3h/L521;11.1h/L617]'),
      'Last 4 weeks, oldest to newest (hours / load): 12.3h/L521, 11.1h/L617.',
    );
    expect(
      appleFactLine(
        '[Last30d:Sports:run 15x 13.1h 121km L1546;ride 11x 22.0h]',
      ),
      'Last 30 days by sport: run 15x 13.1h 121km L1546, ride 11x 22.0h.',
    );
  });

  test('a comparison keeps both figures and the ratio', () {
    expect(
      appleFactLine(
        '[Compare:ride,N:11,Min:348 vs 84 (4.1x),Km:114.0 vs 32.7 (3.5x),Load:258 vs 88 (2.9x),AvgHR:134 vs 129 (+5 bpm)]',
      ),
      'This ride session against the average of 11 other ride sessions in the '
      'last 30 days (this vs average): duration 348 vs 84 min (4.1x), '
      'distance 114.0 vs 32.7 km (3.5x), training load 258 vs 88 (2.9x), '
      'average heart rate 134 vs 129 (+5 bpm).',
    );
  });

  test('the HRV around an activity reads as a sentence', () {
    final text = appleFactLine(
      '[HRV:AroundActivity,PreNight:44ms(2026-10-18),PostNight:38ms(2026-10-19),NightChange:-6ms(-14%),WeeklyAvg:46ms,Note:NightValuesAreWatchMeasuredNotComparableToSpotRMSSD]',
    );
    expect(
      text,
      startsWith(
        'HRV around this activity: overnight (watch) night before 44 ms (2026-10-18), '
        'night after 38 ms (2026-10-19), change -6 ms (-14%).',
      ),
    );
    expect(text, contains('Weekly average 46 ms.'));
    expect(text, isNot(contains('Polar H10')));
    expect(text, contains('never compare their values'));
    expect(
      appleFactLine('[HRV:AroundActivity,Unavailable]'),
      'No HRV was recorded around this activity; its effect on HRV is unknown.',
    );
    const daily = '[HRV:Latest:2026-10-24,Night:40ms]';
    expect(
      appleFactLine(daily),
      'Recovery measurements on 2026-10-24: overnight watch HRV 40ms.',
    );
  });

  test('other lines and plain text stay as they are', () {
    const hrv = '[HRV:7dTrend:10-24:40,10-23:42]';
    expect(appleFactLine(hrv), hrv);
    expect(appleFactLine('plain text'), 'plain text');
    expect(appleFactLine('[broken'), '[broken');
    expect(appleFactLine('[NoColon]'), '[NoColon]');
  });
}
