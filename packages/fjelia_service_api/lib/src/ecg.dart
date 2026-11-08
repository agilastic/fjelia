/// Medical reading of ECG recordings: rhythm patterns, intervals, the median
/// beat and the coach's rules for them. The private package supplies it;
/// every other build gets none, so the app reads an ECG for training only
/// (heart rate, HRV, signal quality).
abstract class EcgClinicalRules {
  /// Whether this build may read ECGs medically right now.
  bool get isAvailable;

  /// The coach's rules for the cloud models; empty when not available.
  String get rules;

  /// The same, short enough for Apple's small context window.
  String get shortRules;

  /// The medical reading of [signal], or null when not available. Pure and
  /// synchronous: the app calls it inside the analysis isolate.
  EcgClinicalReading? read(EcgSignal signal);
}

/// What the medical reading found, as the coach's context lines.
abstract class EcgClinicalReading {
  /// The coach's lines for [meta]: the short form up to 10 minutes, with a
  /// 5-minute timeline beyond.
  List<String> lines(EcgRecordingMeta meta);
}

/// Where and when a recording was made.
class EcgRecordingMeta {
  const EcgRecordingMeta({
    required this.device,
    required this.source,
    required this.recordedAt,
    required this.durationMs,
    required this.linkedToWorkout,
  });

  final String device, source;
  final DateTime recordedAt;
  final int durationMs;
  final bool linkedToWorkout;
}

/// The app's signal processing of a recording, handed to the medical
/// reading: the segments with their R peaks, the 10-second quality windows
/// and the beats that passed them.
class EcgSignal {
  const EcgSignal({
    required this.hz,
    required this.durationSeconds,
    required this.analysedSeconds,
    required this.excluded,
    required this.segments,
    required this.windows,
    required this.beats,
  });

  final double hz, durationSeconds, analysedSeconds;

  /// Why windows were left out, e.g. {'noise': 2, 'no contact': 1}.
  final Map<String, int> excluded;
  final List<EcgSignalSegment> segments;
  final List<EcgSignalWindow> windows;

  /// In time order. [EcgSignalBeat.premature] is already marked.
  final List<EcgSignalBeat> beats;
}

/// A gap-free stretch of the recording.
class EcgSignalSegment {
  const EcgSignalSegment({
    required this.startSeconds,
    required this.raw,
    required this.isoelectric,
    required this.rPeaks,
  });

  final double startSeconds;

  /// As recorded, in microvolts.
  final List<double> raw;

  /// [raw] minus a line through the PR segments of the beats, for shapes
  /// and levels.
  final List<double> isoelectric;

  /// Sample indices of the detected R peaks.
  final List<int> rPeaks;
}

class EcgSignalWindow {
  const EcgSignalWindow({
    required this.segment,
    required this.from,
    required this.to,
    required this.problem,
    required this.noiseRatio,
  });

  /// Index into [EcgSignal.segments]; [from] and [to] are sample indices.
  final int segment, from, to;

  /// Why the window was left out; null when it passed.
  final String? problem;
  final double noiseRatio;
}

class EcgSignalBeat {
  const EcgSignalBeat({
    required this.segment,
    required this.index,
    required this.timeSeconds,
    required this.rrBeforeMs,
    required this.premature,
    required this.shapeCorrelation,
  });

  /// Index into [EcgSignal.segments] and the R peak's sample index there.
  final int segment, index;
  final double timeSeconds;

  /// Null when the beat before it is not a usable neighbour.
  final double? rrBeforeMs;

  /// More than 20 % before the local median interval.
  final bool premature;

  /// Correlation of the beat's QRS with the median beat of the beats at
  /// normal timing (1 when it could not be compared).
  final double shapeCorrelation;
}
