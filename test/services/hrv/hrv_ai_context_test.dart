import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/services/ai_coach_rules.dart';
import 'package:fjelia/services/ai_context_toon_builder.dart';
import 'package:fjelia/services/apple_context_facts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hrv_db.dart';

void main() {
  late AppDatabase db;
  late AiContextToonBuilder builder;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    builder = AiContextToonBuilder(db, now: () => atMin(60 * 24));
  });
  tearDown(() => db.close());

  const before = SpotHrvContext.beforeTraining;
  const after = SpotHrvContext.afterTraining;

  Future<List<String>> hrvLines() async => (await builder.build(null, '', null))
      .split('\n')
      .where((l) => l.startsWith('[HRV:Pair') || l.startsWith('[HRV:Recent'))
      .toList();

  test('the general coach gets a bounded summary of recent pairs', () async {
    // Four workouts in the last week, each with a pre.
    for (var i = 0; i < 4; i++) {
      final start = i * 120 + 600;
      await addActivity(db, 'a$i', start, 60);
      await addReading(db, start - 20, before, rmssd: 60);
      await addReading(db, start + 91, after, rmssd: 45.0 + i);
    }
    final lines = await hrvLines();
    final head = lines.first;
    expect(
      head,
      contains('[HRV:RecentPairs,Window:7d,Workouts:4,WithReadings:4,Shown:3'),
    );
    expect(lines.where((l) => l.startsWith('[HRV:Pair')), hasLength(3));
    // The newest workout comes first, each with its date.
    expect(lines[1], contains('Date:'));
    expect(lines[1], contains('Comparable:yes'));
    expect(lines.join('\n'), isNot(contains('History:')));
  });

  Future<List<String>> trainingHrv() async => (await builder.build(
    null,
    '',
    null,
  )).split('\n').where((l) => l.startsWith('[Analysis:TrainingHRV')).toList();

  test('a rise in training HRV is favourable and is not sleep HRV', () async {
    await addActivity(db, 'up', 700, 60);
    await addReading(db, 680, before, rmssd: 34);
    await addReading(db, 791, after, rmssd: 41);
    final lines = await trainingHrv();
    expect(lines, hasLength(1));
    expect(lines.first, contains('Verdict:better'));
    expect(lines.first, contains('ROSE'));
    expect(lines.first, contains('(favourable)'));
    expect(lines.first, contains('NOT sleep HRV'));
  });

  test('a fall in training HRV is the less favourable direction', () async {
    await addActivity(db, 'down', 700, 60);
    await addReading(db, 680, before, rmssd: 34);
    await addReading(db, 791, after, rmssd: 28);
    final line = (await trainingHrv()).single;
    expect(line, contains('Verdict:worse'));
    expect(line, contains('FELL'));
    expect(line, contains('(less favourable)'));
    // The Apple model reads the sentence, not the compact line.
    expect(appleFactLine(line), startsWith('Training HRV (chest strap)'));
  });

  test('a missing reading gives no change and no verdict', () async {
    await addActivity(db, 'half', 700, 60);
    await addReading(db, 680, before, rmssd: 34);
    final line = (await trainingHrv()).single;
    expect(line, contains('Verdict:none'));
    expect(line, contains('no change is given'));
  });

  test('HRV-T065 an older workout is outside the window', () async {
    await addActivity(db, 'old', -60 * 24 * 10, 60);
    await addReading(db, -60 * 24 * 10 - 20, before);
    expect(await hrvLines(), isEmpty);
  });

  test(
    'workouts without readings are counted, not listed or called rest',
    () async {
      await addActivity(db, 'with', 700, 60);
      await addReading(db, 680, before);
      await addActivity(db, 'without', 900, 60);
      final lines = await hrvLines();
      expect(lines.first, contains('Workouts:2,WithReadings:1,Shown:1'));
      expect(
        lines.first,
        contains('UnlistedWorkoutsHaveNoReadingOrWereOmitted'),
      );
    },
  );

  test('no readings at all adds no HRV pair lines', () async {
    await addActivity(db, 'a', 700, 60);
    expect(await hrvLines(), isEmpty);
  });

  test('the line carries no names, device ids or raw data', () async {
    await addActivity(db, 'secret-activity-id', 700, 60);
    await addReading(db, 680, before);
    final all = (await hrvLines()).join('\n');
    expect(all, isNot(contains('secret-activity-id')));
    expect(all, isNot(contains('h10')));
    expect(all, isNot(contains('Polar')));
    expect(all, isNot(contains('rr_ms')));
  });

  group('Apple gets the same facts as sentences', () {
    const line =
        '[HRV:Pair,Policy:hrv-v1,Analysis:paired-response-v1,Evidence:ab12cd34,'
        'Purpose:retrospective,Sport:cycling,Assoc:unambiguous,WorkoutStart:08:00Z,'
        'WorkoutEnd:10:00Z,EndBasis:providerElapsed,'
        'Pre:60.0ms/07:35Z/seated/300s/settle60s,'
        'Post:45.0ms/10:31Z/seated/300s/settle60s/after31min,'
        'Change:-15.0ms/-25.0%/ln-0.2877,Comparable:yes,Timing:inTargetBand,'
        'History:n=3/need8/insufficientData,Limits:none,Unknown:RPE|Heat|Fuelling|FollowUpNight|PersonalRange]';

    test('figures, delay, comparability and unknowns survive', () {
      final text = appleFactLine(line);
      expect(text, contains('before 60.0 ms at 07:35Z (seated, 300s)'));
      expect(
        text,
        contains(
          'after 45.0 ms at 10:31Z (seated, 300s, 31 minutes after the workout ended)',
        ),
      );
      expect(text, contains('Change -15.0 ms (-25.0%).'));
      expect(text, contains('directly comparable'));
      expect(
        text,
        contains(
          'too few comparable workouts for a personal range yet (3 counted)',
        ),
      );
      expect(
        text,
        contains('Unknown: RPE, Heat, Fuelling, FollowUpNight, PersonalRange.'),
      );
      expect(text, contains('does not show full recovery'));
    });

    test('HRV-T062 a limitation and "not comparable" are not lost', () {
      final text = appleFactLine(
        line
            .replaceFirst('Comparable:yes', 'Comparable:no')
            .replaceFirst('Change:-15.0ms/-25.0%/ln-0.2877', 'Change:none')
            .replaceFirst(
              'Limits:none',
              'Limits:postureMismatch|legacyQualityUnknown',
            ),
      );
      expect(text, contains('NOT directly comparable'));
      expect(text, contains('No valid change is available'));
      expect(text, contains('different positions'));
      expect(text, contains('older reading with unrecorded quality'));
      expect(text, isNot(contains('Change -15')));
    });

    test('a missing side is said, not invented', () {
      final text = appleFactLine(
        line.replaceFirst(RegExp(r'Post:[^,]*'), 'Post:none'),
      );
      expect(text, contains('after none recorded'));
    });

    test('recent pairs say what an unlisted workout is not', () {
      final text = appleFactLine(
        '[HRV:RecentPairs,Window:7d,Workouts:4,WithReadings:2,Shown:2,Note:x]',
      );
      expect(text, contains('2 of 4 workouts have readings'));
      expect(text, contains('not a rest day'));
    });
  });

  group('answer rules', () {
    test(
      'HRV-T064 no training-quality, recovery or plan claim from a delta',
      () {
        for (final rules in [coachAnswerStandard, coachAnswerStandardShort]) {
          expect(rules.toLowerCase(), contains('not a failed session'));
          expect(rules.toLowerCase(), contains('glycogen'));
        }
        expect(coachAnswerStandard, contains('do not change training'));
        expect(coachAnswerStandard, contains('afterNmin'));
        expect(coachAnswerStandard, contains('never compare their values'));
        expect(coachAnswerStandard, contains('Purpose:retrospective'));
        expect(
          coachAnswerStandard,
          contains('what was observed, whether it is comparable'),
        );
      },
    );
  });
}
