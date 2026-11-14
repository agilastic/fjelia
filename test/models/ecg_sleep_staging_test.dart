import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/models/ecg_sleep_staging.dart';

/// Epochs every 30 s from [startSeconds], one per stage in [stages].
List<EcgSleepStageEpoch> epochs(List<int> stages, {int startSeconds = 0}) => [
  for (var i = 0; i < stages.length; i++)
    EcgSleepStageEpoch(
      startOffsetSeconds: startSeconds + i * 30,
      stage: stages[i],
      confidence: .8,
    ),
];

void main() {
  final start = DateTime(2026, 11, 12, 23);
  String at(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  List<String> summary(List<EcgSleepStageEpoch> e) => [
    for (final p in EcgSleepStageEstimate(
      createdAt: start,
      epochs: e,
    ).fiveMinutePhases(start))
      '${at(p.start)}-${at(p.end)} ${p.phase}',
  ];

  test('model labels map to the chart stages', () {
    expect(
      [
        for (final s in [0, 1, 2, 3, 4, 9]) epochs([s]).single.chartStage,
      ],
      ['awake', 'light', 'light', 'deep', 'rem', 'awake'],
    );
  });

  test('a block takes its majority stage; equal blocks merge', () {
    expect(
      summary(
        epochs([
          // 23:00–23:05: 7 × N3, 3 × N2 → deep.
          3, 3, 3, 2, 3, 3, 2, 3, 2, 3,
          // 23:05–23:10: all N3 → merges with the block before.
          3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
          // 23:10–23:15: REM.
          4, 4, 4, 4, 4, 4, 1, 4, 4, 4,
        ]),
      ),
      ['23:00-23:10 deep', '23:10-23:15 rem'],
    );
  });

  test('blocks less than half covered stay gaps, not invented stages', () {
    expect(
      summary([
        ...epochs([2, 2, 2, 2, 2, 2, 2, 2, 2, 2]),
        // 23:05–23:10: only 4 epochs (2 of 5 minutes).
        ...epochs([0, 0, 0, 0], startSeconds: 300),
        ...epochs([4, 4, 4, 4, 4, 4, 4, 4, 4, 4], startSeconds: 600),
      ]),
      ['23:00-23:05 light', '23:10-23:15 rem'],
    );
  });

  test('a tie goes to the stage at the middle of the block', () {
    // Five light then five deep epochs: the epoch nearest 23:02:30 is light.
    expect(summary(epochs([2, 2, 2, 2, 2, 3, 3, 3, 3, 3])), [
      '23:00-23:05 light',
    ]);
    expect(summary(epochs([3, 3, 3, 3, 3, 2, 2, 2, 2, 2])), [
      '23:00-23:05 deep',
    ]);
  });

  test('epochs out of order give the same summary', () {
    final ordered = epochs([3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4]);
    expect(summary(ordered.reversed.toList()), summary(ordered));
    expect(summary(const []), isEmpty);
  });

  test('the estimate is kept in the recording metadata', () {
    final estimate = EcgSleepStageEstimate(
      createdAt: DateTime.utc(2026, 11, 13, 6, 30),
      epochs: epochs([2, 3, 4]),
    );
    final metadata = jsonEncode({
      'capture_purpose': 'sleep',
      'sleep_stage_estimate': estimate.toJson(),
    });
    final back = EcgSleepStageEstimate.fromRecordingMetadata(metadata)!;
    expect(back.modelVersion, estimate.modelVersion);
    expect(back.createdAt.isAtSameMomentAs(estimate.createdAt), isTrue);
    expect([for (final e in back.epochs) e.stage], [2, 3, 4]);

    expect(EcgSleepStageEstimate.fromRecordingMetadata('{}'), isNull);
    expect(
      EcgSleepStageEstimate.fromRecordingMetadata(
        jsonEncode({
          'sleep_stage_estimate': {...estimate.toJson(), 'version': 2},
        }),
      ),
      isNull,
    );
    expect(EcgSleepStageEstimate.fromRecordingMetadata('not json'), isNull);
  });
}
