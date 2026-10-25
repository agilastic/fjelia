import '../../models/hrv_pair_assessment.dart';

/// Short, plain wording of why a pair is incomplete or limited. The card and
/// the AI context are built from the same reason codes.
String hrvReasonLabel(HrvReason r) => switch (r) {
  HrvReason.missingPre => 'No measurement before this workout.',
  HrvReason.missingPost => 'No measurement after this workout yet.',
  HrvReason.invalidSignal => 'A measurement had too weak a signal to use.',
  HrvReason.legacyQualityUnknown =>
    'An older measurement: its signal quality was not recorded.',
  HrvReason.postureMismatch =>
    'Before and after were taken in different positions, so the change is not compared.',
  HrvReason.durationMismatch =>
    'Before and after used different recording lengths, so the change is not compared.',
  HrvReason.metricMismatch =>
    'Before and after are different HRV measures, so the change is not compared.',
  HrvReason.clockUncertain =>
    'The clock was uncertain, so the exact timing is not trusted.',
  HrvReason.unknownActualEnd =>
    'The actual end of the workout is not known, so the delay cannot be given.',
  HrvReason.interveningWorkout =>
    'Another workout followed, so a later reading would not describe this one alone.',
  HrvReason.postOutsideTargetBand =>
    'Taken outside the usual 25–40 minutes after the end. It is compared only with workouts measured at a similar delay.',
  HrvReason.ambiguousActivity =>
    'Workouts overlap, so the readings cannot be assigned with confidence.',
  HrvReason.insufficientComparableHistory =>
    'Not enough comparable workouts yet.',
  HrvReason.invalidValue => 'A value was not usable, so no change is shown.',
};

/// The reasons worth saying out loud, in a stable order.
List<HrvReason> hrvVisibleReasons(HrvPairAssessment a) {
  const order = [
    HrvReason.ambiguousActivity,
    HrvReason.interveningWorkout,
    HrvReason.unknownActualEnd,
    HrvReason.clockUncertain,
    HrvReason.postureMismatch,
    HrvReason.durationMismatch,
    HrvReason.metricMismatch,
    HrvReason.invalidValue,
    HrvReason.invalidSignal,
    HrvReason.postOutsideTargetBand,
    HrvReason.legacyQualityUnknown,
  ];
  return [
    for (final r in order)
      if (a.reasons.contains(r)) r,
  ];
}

String hrvSigned(double v, {int digits = 0, String unit = ''}) {
  final rounded = v.toStringAsFixed(digits);
  final text = rounded.startsWith('-') ? rounded.substring(1) : rounded;
  final zero = double.parse(rounded) == 0;
  final sign = zero ? '' : (v < 0 ? '−' : '+');
  return '$sign$text$unit';
}

String hrvMinutes(Duration d) {
  final m = d.inMinutes;
  return m < 60 ? '$m min' : '${m ~/ 60} h ${m % 60} min';
}
