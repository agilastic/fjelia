import 'stimulus.dart';

/// How a planned session was carried out, judged by duration and intensity
/// separately. A shorter session is not taken as a sign of low fitness: why
/// it was shorter decides that.
enum ExecutionOutcome {
  completed,

  /// Clearly longer than planned at the planned intensity.
  longer,

  /// Shorter than planned, reason not known yet.
  partial,

  /// Harder than planned, whatever its length: the extra stress counts.
  tooHard,

  /// The quality the session was for was not reached.
  tooEasy,

  /// Shorter because of fatigue or pain, said by the athlete or shown by a
  /// yellow or red morning readiness.
  stoppedFatigue,

  /// Shorter for a reason outside training (time, weather, other).
  shortenedExternal,
  missed,
}

/// Why a session was shorter, as the athlete answered.
const shortReasons = ['time', 'weather', 'fatigue', 'pain', 'other'];

/// `hard`, `easy` or `on` against the plan; null when the workout has no
/// heart-rate zones. Hard: a good part above what an easy or tempo session
/// asks for, or a load well above plan at about the planned length. Easy:
/// less than half the minutes at tempo or threshold a quality session asks.
String? intensityVerdict(
  Stimulus planned,
  Stimulus done, {
  double? loadRatio,
  double? durationRatio,
}) {
  if (!done.zonesKnown) return null;
  final share = done.minutes <= 0 ? 0.0 : 1 / done.minutes;
  final hard = switch (planned.level) {
    0 => done.z3Min >= 10 && done.z3Min * share >= .3,
    1 => done.z4Min >= 10 && done.z4Min * share >= .3,
    _ => false,
  };
  final heavy =
      loadRatio != null &&
      loadRatio > 1.25 &&
      (durationRatio ?? 1) <= 1.1 &&
      planned.level < 2;
  if (hard || heavy) return 'hard';
  final easy = switch (planned.level) {
    1 => done.z3Min < planned.z3Min * .5,
    2 => done.z4Min < planned.z4Min * .5,
    _ => false,
  };
  return easy ? 'easy' : 'on';
}

/// The outcome from duration, intensity, the athlete's reason for a shorter
/// session and the morning readiness of its day.
ExecutionOutcome executionOutcome({
  required double durationRatio,
  String? intensity,
  String? shortReason,
  String? readinessLevel,
}) {
  if (intensity == 'hard') return ExecutionOutcome.tooHard;
  if (durationRatio < .8) {
    if (shortReason == 'fatigue' || shortReason == 'pain') {
      return ExecutionOutcome.stoppedFatigue;
    }
    if (shortReason != null) return ExecutionOutcome.shortenedExternal;
    if (readinessLevel == 'yellow' || readinessLevel == 'red') {
      return ExecutionOutcome.stoppedFatigue;
    }
    return ExecutionOutcome.partial;
  }
  if (intensity == 'easy') return ExecutionOutcome.tooEasy;
  if (durationRatio > 1.25) return ExecutionOutcome.longer;
  return ExecutionOutcome.completed;
}
