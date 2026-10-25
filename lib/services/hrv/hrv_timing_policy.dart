/// Versioned timing and eligibility defaults for pre/post training HRV.
/// These are product policies, not physiological thresholds: change them only
/// through a new [version], and read them here instead of in widgets.
class HrvTimingPolicy {
  const HrvTimingPolicy({
    this.version = 'hrv-v1',
    this.preWindow = const Duration(hours: 3),
    this.postWindow = const Duration(minutes: 120),
    this.reminderOffset = const Duration(minutes: 30),
    this.targetBandStart = const Duration(minutes: 25),
    this.targetBandEnd = const Duration(minutes: 40),
    this.catchUp = const Duration(minutes: 15),
    this.expiry = const Duration(minutes: 90),
    this.snooze = const Duration(minutes: 10),
    this.maxSnoozes = 1,
    this.futureTolerance = const Duration(seconds: 120),
    this.cohortHorizon = const Duration(days: 90),
    this.cohortMinimum = 8,
    this.cohortMinimumSpan = const Duration(days: 14),
    this.maxPlatformRequests = 8,
  });

  final String version;

  /// A pre sampling must end this long before the start at the latest.
  final Duration preWindow;

  /// A post sampling must start within this long after the end.
  final Duration postWindow;

  /// Reminder target after the actual end. Not a sampling time.
  final Duration reminderOffset;

  /// Descriptive band for the default protocol, not a recovery cutoff.
  final Duration targetBandStart, targetBandEnd;

  /// A workout found this late after its due time still gets one reminder.
  final Duration catchUp;

  /// No new scheduling or action from this long after the actual end.
  final Duration expiry;
  final Duration snooze;
  final int maxSnoozes;
  final Duration futureTolerance;
  final Duration cohortHorizon;
  final int cohortMinimum;
  final Duration cohortMinimumSpan;
  final int maxPlatformRequests;

  /// Due and expiry must be ordered, or the settings are contradictory.
  bool get consistent =>
      reminderOffset > Duration.zero &&
      reminderOffset + catchUp <= expiry &&
      snooze > Duration.zero;

  /// Minutes of the timing cohort a post at [delay] belongs to. A 10, 30 and
  /// 60 minute protocol are different cohorts and never mix.
  int timingCohort(Duration delay) {
    final m = delay.inMinutes;
    if (delay >= targetBandStart && delay <= targetBandEnd) {
      return reminderOffset.inMinutes;
    }
    // Everything else is bucketed to the nearest 10 minutes.
    return ((m + 5) ~/ 10) * 10;
  }

  bool inTargetBand(Duration delay) =>
      delay >= targetBandStart && delay <= targetBandEnd;

  static const standard = HrvTimingPolicy();
}
