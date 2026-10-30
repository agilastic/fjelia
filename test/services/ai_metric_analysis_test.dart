import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/services/ai_metric_analysis.dart';
import 'package:fjelia/services/briefing_brief.dart';
import 'package:fjelia/models/chat_message.dart';
import 'package:fjelia/services/apple_coach_request.dart';
import 'package:fjelia/services/apple_context_facts.dart';
import 'package:fjelia/services/briefing_text.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

HrvRecord _row(int daysAgo, {double? hrv, int? rhr, double? stress}) =>
    HrvRecord(
      id: daysAgo,
      date: DateTime(2026, 10, 28).subtract(Duration(days: daysAgo)),
      hrvLastNight: hrv,
      hrvWeeklyAvg: null,
      restingHeartRate: rhr,
      stressLevel: stress,
      bodyBattery: null,
      computedEnergie: null,
      spo2: null,
      respirationRate: null,
      skinTempDelta: null,
      hrvIntradayJson: null,
      source: null,
    );

List<String> _lines(List<HrvRecord> hrv) => MetricAnalysis(
  DateTime(2026, 10, 28, 21),
).lines(hrv: hrv, sleep: const [], wellness: const []);

String _line(List<String> lines, String name) =>
    lines.firstWhere((l) => l.startsWith('[Analysis:$name,'));

void main() {
  // Newest first; the earlier nights average 55 ms and 47 bpm.
  List<HrvRecord> series(double latestHrv, int latestRhr) => [
    _row(0, hrv: latestHrv, rhr: latestRhr, stress: 22),
    for (var i = 1; i <= 8; i++) _row(i, hrv: 55, rhr: 47, stress: 22),
  ];

  test('a falling HRV well below average is worse, never good', () {
    final lines = _lines(series(40, 47));
    final hrv = _line(lines, 'SleepHRV');
    expect(hrv, contains('Verdict:clearlyWorse'));
    expect(hrv, contains('Trend:falling'));
    expect(hrv, contains('Delta7d:-27%'));
    expect(hrv, contains('below your 7-day average of 55 ms'));
    expect(
      hrv,
      contains('MUCH WORSE than usual (state RED; higher is better)'),
    );
    expect(lines.first, contains('WorseThanAverage:SleepHRV'));
  });

  test('a rising HRV above average is better, not strain', () {
    final lines = _lines(series(66, 47));
    final hrv = _line(lines, 'SleepHRV');
    expect(hrv, contains('Verdict:better'));
    expect(hrv, contains('Trend:rising'));
    expect(hrv, contains('above your 7-day average'));
    expect(lines.first, contains('BetterThanAverage:SleepHRV'));
    expect(lines.first, contains('WorseThanAverage:none'));
  });

  test('resting heart rate is judged the other way round', () {
    expect(
      _line(_lines(series(55, 56)), 'RHR'),
      contains('Verdict:clearlyWorse'),
    );
    expect(_line(_lines(series(55, 43)), 'RHR'), contains('Verdict:better'));
  });

  test('a record from an earlier day is not called today', () {
    final old = [for (var i = 3; i <= 11; i++) _row(i, hrv: i == 3 ? 40 : 55)];
    final hrv = _line(_lines(old), 'SleepHRV');
    expect(hrv, contains('DaysAgo:3'));
    expect(hrv, contains('(3 days ago (2026-10-25))'));
  });

  test('the Apple model gets the sentence and today\'s date', () {
    final line = _line(_lines(series(40, 47)), 'SleepHRV');
    expect(
      appleFactLine(line),
      startsWith('Sleep HRV (overnight watch) 40 ms (today): 27% below'),
    );
    expect(
      appleFactLine(
        '[Context:V4][Today:2026-10-28,Weekday:Wed,TimeNow:20:58][Range:60d]',
      ),
      contains('Today is Wed 2026-10-28'),
    );
  });

  test('a briefing is flattened to one plain paragraph', () {
    expect(
      flattenBriefing('**Heute** war ok.\n\n- HRV 40 ms\n- RHR 47\n1. Ruhe\n'),
      'Heute war ok. HRV 40 ms RHR 47 Ruhe',
    );
    expect(flattenBriefing('"Alles gut."'), 'Alles gut.');
    expect(flattenBriefing('a\r\nb\tc'), 'a b c');
  });

  List<String> briefLines({String? trainingHrv}) =>
      MetricAnalysis(DateTime(2026, 10, 28, 21)).lines(
        hrv: series(40, 56),
        sleep: const [],
        wellness: const [],
        done: const ['running/88'],
        tomorrow: const ['cycling_road/36', 'strength/35'],
        trainingHrv: trainingHrv,
      );

  test('the Brief ranks the findings and carries the plan', () {
    final brief = BriefingBrief.parse(
      briefLines(trainingHrv: 'up').join('\n'),
    )!;
    expect(brief.readiness, 'red');
    // Worst first: sleep HRV and resting heart rate are both red.
    expect(brief.findings.first, 'hrvLow');
    expect(brief.findings, contains('rhrUp'));
    expect(brief.findings.length, lessThanOrEqualTo(3));
    expect(brief.done, ['running/88']);
    expect(brief.tomorrow, ['cycling_road/36', 'strength/35']);
    expect(brief.trainingHrv, 'up');
    final text = brief.toModelText();
    expect(text, contains('Readiness RED'));
    expect(text, contains('Done today: running 88 min'));
    expect(text, contains('cycling road 36 min and strength 35 min'));
    expect(text, contains('rose (favourable)'));
    // Words, not the figures the screen already shows.
    expect(text, isNot(contains('55')));
    expect(text, isNot(contains('27%')));
  });

  test('the Apple briefing gets the finished analysis before the question', () {
    final request = AppleCoachRequest.build(
      [const ChatMessage(text: 'Give me my evening briefing.', isUser: true)],
      '[Context:V4][Today:2026-10-28,Weekday:Wed,TimeNow:21:15][Range:60d]\n'
      '${briefLines().join('\n')}\n'
      '[HRV:Pair:Sport:running,Change:+3.3ms/+9.2%,Comparable:yes]\n'
      '[HRV:Latest:2026-10-28,Night:40ms]\n'
      '[TodayWorkout:Status:rest_day]',
      briefingInstructions:
          'You are Fjelia AI Coach. Generate a short evening briefing.',
      budget: 4600,
    );
    final prompt = request.prompt;
    expect(prompt, contains("TODAY'S ANALYSIS"));
    expect(
      prompt.indexOf("TODAY'S ANALYSIS"),
      lessThan(prompt.indexOf('Latest user message')),
    );
    expect(prompt, contains('Readiness RED'));
    // The long per-metric sentences and the old HRV lines stay out.
    expect(prompt, isNot(contains('7-day average')));
    expect(prompt, isNot(contains('+3.3')));
    expect(prompt, isNot(contains('Night:40ms')));
    expect(prompt, contains('No workout is scheduled for today'));
    expect(request.instructions, contains('at most 45 words'));
    expect(request.instructions, contains('DO NOT list or repeat'));
  });

  test(
    'a full briefing request fits the budget on the first try and on retry',
    () {
      for (final budget in [4600, 3600]) {
        final request = AppleCoachRequest.build(
          [
            const ChatMessage(
              text: 'Give me my evening briefing. Write it in German.',
              isUser: true,
            ),
          ],
          '[Context:V4][Today:2026-10-28,Weekday:Wed,TimeNow:21:15][Range:60d]\n'
          '${briefLines(trainingHrv: 'down').join('\n')}\n'
          '${'[Activities:today:${'run ' * 80}]\n' * 6}[TodayWorkout:Status:rest_day]',
          briefingInstructions:
              'You are Fjelia AI Coach. Generate a short evening briefing.',
          budget: budget,
        );
        expect(request.inputBytes, lessThanOrEqualTo(budget));
        expect(request.prompt, contains('Readiness RED'));
      }
    },
  );

  group('briefing guard', () {
    test('short, in the right language and not a copy is usable', () {
      expect(
        briefingIsUsable(
          'Dein Schlaf war zu kurz und die Energie ist niedrig. Trainiere morgen locker und geh früh ins Bett.',
          languageCode: 'de',
        ),
        isTrue,
      );
    });
    test('the pasted fact list is rejected', () {
      expect(
        briefingIsUsable(
          "Today's readiness from sleep HRV and resting heart rate is YELLOW: functional overload. Compared with your own recent averages these are better: none.",
          languageCode: 'de',
        ),
        isFalse,
      );
      expect(
        briefingIsUsable(
          'Resting heart rate 47 bpm (today): 3 bpm above your 7-day average of 44 bpm; rising.',
          languageCode: 'en',
        ),
        isFalse,
      );
    });
    test(
      'too long, too many figures or English in a German app are rejected',
      () {
        expect(
          briefingIsUsable(
            List.filled(80, 'wort').join(' '),
            languageCode: 'de',
          ),
          isFalse,
        );
        expect(
          briefingIsUsable(
            'HRV 40 und RHR 47 bei Schlaf 6,1 und Energie 5 und Stress 22.',
            languageCode: 'de',
          ),
          isFalse,
        );
        expect(
          briefingIsUsable(
            'You are tired and the plan is fine, keep the training with your coach.',
            languageCode: 'de',
          ),
          isFalse,
        );
      },
    );
    test('an empty answer is rejected', () {
      expect(briefingIsUsable('  ', languageCode: 'en'), isFalse);
    });
  });

  test('the app writes a short briefing in the app language when needed', () {
    final brief = BriefingBrief.parse(briefLines().join('\n'))!;
    final de = lookupAppLocalizations(const Locale('de'));
    final text = brief.localText(de);
    expect(text, startsWith('Du bist deutlich belastet.'));
    expect(text, contains('niedrige Schlaf-HRV'));
    expect(text, endsWith('Erholung zuerst: leichter Tag oder Pause.'));
    expect(text.split(RegExp(r'\s+')).length, lessThan(40));
    // The chest-strap reading is a remark of its own, never a reason.
    final up = BriefingBrief(
      readiness: 'yellow',
      findings: const ['sleepShort'],
      trainingHrv: 'up',
    ).localText(de);
    expect(up, contains('Hauptgründe: zu wenig Schlaf.'));
    expect(
      up,
      contains('Deine HRV ist nach dem Training gestiegen, ein gutes Zeichen.'),
    );
    expect(
      up.indexOf('Hauptgründe'),
      lessThan(up.indexOf('nach dem Training')),
    );
    const green = BriefingBrief(readiness: 'green');
    expect(green.localText(de), contains('Keiner deiner Werte'));
  });
}
