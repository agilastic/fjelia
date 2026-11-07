import 'dart:math' as math;

import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/ecg.dart';
import 'package:fjelia/services/coach_tasks.dart';
import 'package:fjelia/services/ecg_analysis.dart';
import 'package:fjelia/services/ecg_coach_context.dart';
import 'package:flutter_test/flutter_test.dart';

const hz = 130.0;

/// [seconds] of a regular rhythm at 60 bpm, in H10-sized frames.
List<EcgChunk> regularEcg(double seconds) {
  double g(double t, double at, double amp, double sigma) =>
      amp * math.exp(-math.pow(t - at, 2) / (2 * sigma * sigma));
  final n = (seconds * hz).round();
  final values = List<num>.generate(n, (i) {
    final t = i / hz;
    final d = t - (t + .5).floorToDouble() + .5 - .5;
    return (g(d, -.16, 120, .022) +
            g(d, 0, 1200, .012) +
            g(d, .03, -300, .012) +
            g(d, .28, 300, .045))
        .round();
  });
  return [
    for (var i = 0; i < n; i += 73)
      EcgChunk(
        offsetUs: (i / hz * 1e6).round(),
        microvolts: values.sublist(i, math.min(n, i + 73)),
      ),
  ];
}

EcgRecording ecg(
  String id,
  DateTime at, {
  String? activityId,
  int seconds = 120,
  String kind = 'waveform',
}) => EcgRecording(
  recordingId: id,
  recordedAt: at,
  source: 'Polar H10',
  deviceName: 'Polar H10 1234',
  kind: kind,
  status: 'complete',
  sampleRateHz: kind == 'waveform' ? hz : null,
  sampleCount: (seconds * hz).round(),
  durationMs: seconds * 1000,
  activityId: activityId,
  metadataJson: '{}',
);

ActivityRecord run(String id, DateTime start, {int minutes = 60}) =>
    ActivityRecord(
      id: 1,
      activityId: id,
      name: 'Morning run',
      type: 'running',
      startDate: start,
      durationSeconds: minutes * 60,
    );

void main() {
  final now = DateTime(2026, 11, 7, 18);

  group('which questions are about the ECG', () {
    test('the examples of the request, in English and German', () {
      for (final q in [
        'Analyze my ECG from yesterday’s run.',
        'Were there any irregularities during my workout?',
        'What happened to my heart rhythm at minute 35?',
        'Compare my heart rate with the ECG recording.',
        'Does the ECG show anything unusual during exercise?',
        'Was zeigt mein EKG?',
        'Hatte ich Herzstolpern beim Lauf?',
        'Gab es Unregelmäßigkeiten im Training?',
        'Mon ECG est-il normal ?',
        'Mitä EKG näyttää?',
      ]) {
        expect(asksAboutEcg(q), isTrue, reason: q);
      }
    });

    test('ordinary training questions load nothing', () {
      for (final q in [
        'How was my pace?',
        'Wie war mein Lauf?',
        '¿Qué tal mi ritmo?',
        'Was my rhythm on the hills good?',
        'Should I rest tomorrow?',
      ]) {
        expect(asksAboutEcg(q), isFalse, reason: q);
      }
    });

    test('a period and a clock time in the question', () {
      expect(askedMinutes('what happened at minute 35?'), (from: 35, to: 36));
      expect(askedMinutes('zwischen Minute 30-40'), (from: 30, to: 40));
      expect(askedMinutes('in der 12. Minute'), (from: 12, to: 13));
      expect(askedMinutes('my ECG'), isNull);
      expect(askedClock('the recording at 14:30'), (hour: 14, minute: 30));
      expect(askedClock('um 7.05 Uhr'), (hour: 7, minute: 5));
      expect(askedClock('ran 10.5 km'), isNull);
    });
  });

  group('which recording', () {
    final activity = run('a1', DateTime(2026, 11, 7, 7));
    final linked = ecg('linked', DateTime(2026, 11, 7, 7, 2), activityId: 'a1');
    final during = ecg('during', DateTime(2026, 11, 7, 7, 40));
    final other = ecg('other', DateTime(2026, 11, 6, 14, 30));

    test('an activity has its linked recordings and those taken during it', () {
      expect(activityEcgs([linked, during, other], activity), [linked, during]);
    });

    test('several fit and nothing tells them apart: the coach asks', () {
      final pick = pickEcg(
        [linked, during],
        question: 'Analyse the ECG',
        activity: activity,
        now: now,
      );
      expect(pick, isA<SeveralEcgs>());
      final line = ecgChoiceLine((pick as SeveralEcgs).recordings);
      expect(line, contains('ask the athlete which one'));
      expect(line, isNot(contains('[ECG:Summary')));
    });

    test('a clock time, a day or "last" picks one', () {
      OneEcg one(String q, {ActivityRecord? a}) =>
          pickEcg([during, linked, other], question: q, activity: a, now: now)
              as OneEcg;
      expect(one('the ECG at 7:40', a: activity).recording, during);
      expect(one('the ECG from yesterday').recording, other);
      expect(one('my last ECG').recording.recordingId, 'during');
    });

    test('an unrelated recording is never taken', () {
      final pick = pickEcg(
        [other],
        question: 'Analyse the ECG',
        activity: activity,
        now: now,
      );
      expect(pick, isA<NoEcg>());
      expect(
        pickEcg([linked], question: 'ECG at 14:30', now: now),
        isA<NoEcg>(),
      );
    });
  });

  group('context lines', () {
    final analysis = analyzeEcg(regularEcg(120), hz);
    final row = ecg('e1', DateTime(2026, 11, 7, 7, 10), activityId: 'a1');

    test('stage 1 tells the coach a recording exists, nothing more', () {
      final line = ecgAvailableLine(row);
      expect(line, startsWith('[ECG:Available,Id:e1,'));
      expect(line, contains('Duration:120s'));
      expect(line, contains('Activity:a1'));
      expect(line, contains('not loaded'));
      // It does not turn the chat into an ECG chat.
      expect(coachTaskFor(line), isNot(CoachTask.ecg));
    });

    test('stage 2 is the full context of the ECG sheet', () {
      final lines = ecgDetailLines(row, analysis);
      expect(
        lines,
        analysis.contextLines(
          device: row.deviceName,
          source: row.source,
          recordedAt: row.recordedAt,
          linkedToWorkout: true,
        ),
      );
      expect(coachTaskFor(lines.join('\n')), CoachTask.ecg);
    });

    test('long recordings get the timeline, as on the ECG sheet', () {
      final long = ecg('e2', row.recordedAt, seconds: 900);
      final a = analyzeEcg(regularEcg(900), hz);
      expect(
        ecgDetailLines(long, a),
        a.contextLinesWithTimeline(
          device: long.deviceName,
          source: long.source,
          recordedAt: long.recordedAt,
          linkedToWorkout: false,
        ),
      );
    });

    test('a workout minute is placed in the recording, nothing removed', () {
      final activity = run('a1', DateTime(2026, 11, 7, 7));
      final lines = ecgDetailLines(
        row,
        analysis,
        minutes: (from: 11, to: 12),
        activity: activity,
      );
      expect(lines.sublist(0, lines.length - 1), ecgDetailLines(row, analysis));
      expect(
        lines.last,
        '[ECG:Focus,Asked:workout minute 11–12,ECG:60–120s, starting 600s into the workout]',
      );
      final outside = ecgDetailLines(
        row,
        analysis,
        minutes: (from: 35, to: 36),
        activity: activity,
      );
      expect(outside.last, contains('Outside the recording'));
    });

    test('a report has no analysis, and says so', () {
      final report = ecg('r1', row.recordedAt, kind: 'report');
      final lines = ecgDetailLines(report, null);
      expect(lines.last, contains('nothing about rhythm or beats is known'));
    });
  });
}
