import 'dart:convert';

import 'garmin_data.dart' show SleepPhase;

/// One 30-second output window from the ECG-only sleep model.
class EcgSleepStageEpoch {
  const EcgSleepStageEpoch({
    required this.startOffsetSeconds,
    required this.stage,
    required this.confidence,
  });

  final int startOffsetSeconds;

  /// 0=Wake, 1=N1, 2=N2, 3=N3, 4=REM (upstream model labels).
  final int stage;
  final double confidence;

  String get chartStage => switch (stage) {
    0 => 'awake',
    1 || 2 => 'light',
    3 => 'deep',
    4 => 'rem',
    _ => 'awake',
  };

  Map<String, Object> toJson() => {
    'start_seconds': startOffsetSeconds,
    'stage': stage,
    'confidence': confidence,
  };

  factory EcgSleepStageEpoch.fromJson(Map<String, dynamic> json) =>
      EcgSleepStageEpoch(
        startOffsetSeconds: (json['start_seconds'] as num).toInt(),
        stage: (json['stage'] as num).toInt(),
        confidence: (json['confidence'] as num).toDouble(),
      );
}

class EcgSleepStageEstimate {
  const EcgSleepStageEstimate({
    required this.createdAt,
    required this.epochs,
    this.modelVersion = 'primary_model_only_ecg/epoch_0369',
  });

  final DateTime createdAt;
  final String modelVersion;
  final List<EcgSleepStageEpoch> epochs;

  List<SleepPhase> phases(DateTime recordingStart) => [
    for (final epoch in epochs)
      SleepPhase(
        recordingStart.add(Duration(seconds: epoch.startOffsetSeconds)),
        recordingStart.add(Duration(seconds: epoch.startOffsetSeconds + 30)),
        epoch.chartStage,
      ),
  ];

  /// Quantize the model's 30-second epochs into five-minute summary blocks.
  /// The raw epochs remain in recording metadata for traceability. A block
  /// takes the stage covering the most observed time; blocks with less than
  /// half their duration covered are omitted instead of filled in.
  List<SleepPhase> fiveMinutePhases(DateTime recordingStart) {
    const stepSeconds = 5 * 60;
    final ordered = [...epochs]
      ..sort((a, b) => a.startOffsetSeconds.compareTo(b.startOffsetSeconds));
    if (ordered.isEmpty) return const [];
    final endSeconds = ordered.fold<int>(
      0,
      (end, epoch) => end > epoch.startOffsetSeconds + 30
          ? end
          : epoch.startOffsetSeconds + 30,
    );
    final result = <SleepPhase>[];
    for (
      var blockStart = 0;
      blockStart < endSeconds;
      blockStart += stepSeconds
    ) {
      final blockEnd = (blockStart + stepSeconds).clamp(0, endSeconds);
      final totals = <String, int>{};
      final coveredEpochs = <EcgSleepStageEpoch>[];
      for (final epoch in ordered) {
        final overlap =
            (epoch.startOffsetSeconds + 30)
                .clamp(blockStart, blockEnd)
                .toInt() -
            epoch.startOffsetSeconds.clamp(blockStart, blockEnd);
        if (overlap <= 0) continue;
        totals[epoch.chartStage] = (totals[epoch.chartStage] ?? 0) + overlap;
        coveredEpochs.add(epoch);
      }
      final coverage = totals.values.fold<int>(0, (sum, value) => sum + value);
      if (totals.isEmpty || coverage * 2 < blockEnd - blockStart) continue;
      final maxDuration = totals.values.reduce((a, b) => a > b ? a : b);
      final tiedStages = totals.entries
          .where((entry) => entry.value == maxDuration)
          .map((entry) => entry.key)
          .toSet();
      final midpoint = (blockStart + blockEnd) / 2;
      final centerEpoch = coveredEpochs.reduce((a, b) {
        final aDistance = (a.startOffsetSeconds + 15 - midpoint).abs();
        final bDistance = (b.startOffsetSeconds + 15 - midpoint).abs();
        return aDistance <= bDistance ? a : b;
      });
      final stage = tiedStages.contains(centerEpoch.chartStage)
          ? centerEpoch.chartStage
          : tiedStages.first;
      final start = recordingStart.add(Duration(seconds: blockStart));
      final end = recordingStart.add(Duration(seconds: blockEnd));
      if (result.isNotEmpty &&
          result.last.phase == stage &&
          result.last.end.isAtSameMomentAs(start)) {
        result[result.length - 1] = SleepPhase(result.last.start, end, stage);
      } else {
        result.add(SleepPhase(start, end, stage));
      }
    }
    return result;
  }

  Map<String, Object> toJson() => {
    'version': 1,
    'model': modelVersion,
    'created_at': createdAt.toUtc().toIso8601String(),
    'epochs': [for (final epoch in epochs) epoch.toJson()],
  };

  factory EcgSleepStageEstimate.fromJson(Map<String, dynamic> json) =>
      EcgSleepStageEstimate(
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        modelVersion: json['model'] as String? ?? 'unknown',
        epochs: [
          for (final item in json['epochs'] as List)
            EcgSleepStageEpoch.fromJson(item as Map<String, dynamic>),
        ],
      );

  static EcgSleepStageEstimate? fromRecordingMetadata(String metadataJson) {
    try {
      final metadata = Map<String, dynamic>.from(
        (jsonDecode(metadataJson) as Map).cast<String, dynamic>(),
      );
      final value = metadata['sleep_stage_estimate'] as Map<String, dynamic>?;
      if (value == null || value['version'] != 1) return null;
      return EcgSleepStageEstimate.fromJson(value);
    } catch (_) {
      return null;
    }
  }
}
