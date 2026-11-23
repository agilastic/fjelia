/// FjeliaPro heart-rate zone trends: how the time in zones Z1–Z5 changes over
/// weeks and months, against the plan. The private package computes them;
/// every other build has none, as it never offers FjeliaPro.
///
/// The figures describe; they never say whether a distribution is good. A
/// week without Z5 is a week without Z5, not a warning.
library;

/// The five zones are indexed 0–4 in every list of this file.
const hrZoneCount = 5;

/// One workout's time in Z1–Z5, computed once from its timestamped heart
/// rate with the zone definition in force when it was recorded, and kept.
class HrZoneWorkout {
  const HrZoneWorkout({
    required this.activityId,
    required this.sport,
    required this.start,
    required this.elapsedSeconds,
    required this.coveredSeconds,
    required this.zoneSeconds,
    required this.definitionId,
  });

  final String activityId;

  /// The sport family the zones belong to: `running`, `cycling`,
  /// `swimming` or `other`.
  final String sport;

  /// Local start time; days, weeks and months are local calendar ones.
  final DateTime start;

  /// The workout's own duration.
  final double elapsedSeconds;

  /// Time with valid heart rate. Never more than [elapsedSeconds]; the rest
  /// is missing heart rate, never Z1.
  final double coveredSeconds;

  /// Seconds in Z1–Z5; they add up to [coveredSeconds].
  final List<double> zoneSeconds;

  /// The zone definition the seconds were computed with.
  final int definitionId;
}

/// Totals over a set of workouts.
class HrZoneTotals {
  const HrZoneTotals({
    required this.zoneSeconds,
    required this.coveredSeconds,
    required this.elapsedSeconds,
    required this.workouts,
    required this.sports,
  });

  static const empty = HrZoneTotals(
    zoneSeconds: [0, 0, 0, 0, 0],
    coveredSeconds: 0,
    elapsedSeconds: 0,
    workouts: 0,
    sports: {},
  );

  final List<double> zoneSeconds;
  final double coveredSeconds, elapsedSeconds;
  final int workouts;
  final Set<String> sports;

  /// Seconds of workout time without valid heart rate.
  double get missingSeconds =>
      (elapsedSeconds - coveredSeconds).clamp(0, double.infinity).toDouble();

  /// Share of workout time with valid heart rate, 0–1.
  double get coverage =>
      elapsedSeconds > 0 ? coveredSeconds / elapsedSeconds : 0;

  /// Share of each zone in the heart-rate time, 0–1 (not of workout time).
  List<double> get zoneShares => [
        for (final s in zoneSeconds)
          coveredSeconds > 0 ? s / coveredSeconds : 0,
      ];

  /// Easy (Z1+Z2), middle (Z3) and hard (Z4+Z5) seconds.
  double get easySeconds => zoneSeconds[0] + zoneSeconds[1];
  double get middleSeconds => zoneSeconds[2];
  double get hardSeconds => zoneSeconds[3] + zoneSeconds[4];

  /// Different sports with different zone boundaries are added up here.
  bool get mixedSports => sports.length > 1;
}

enum HrZoneGrouping { day, week, month }

/// One bar of the chart: a day, week or month.
class HrZonePeriod {
  const HrZonePeriod({
    required this.start,
    required this.end,
    required this.totals,
    required this.partial,
  });

  /// First day and the day after the last one (local dates).
  final DateTime start, end;
  final HrZoneTotals totals;

  /// The period is cut by the window or not over yet: its totals are not a
  /// full week or month.
  final bool partial;
}

/// The change from one window to the next, in seconds and relative.
class HrZoneChange {
  const HrZoneChange(this.previous, this.recent);
  final double previous, recent;
  double get delta => recent - previous;

  /// Relative change, null when the previous window had none.
  double? get relative => previous > 0 ? delta / previous : null;
}

/// What the two windows show, as plain observations. Codes, so the app says
/// them in its language; never a verdict on good or bad.
enum HrZoneObservation {
  /// Too little heart-rate time in one of the windows to compare.
  insufficientData,

  /// Total training time rose, fell, or stayed within ±10 %.
  volumeUp,
  volumeDown,
  volumeSteady,

  /// Time in Z4+Z5 rose while the total time rose as well (or fell).
  hardUpWithVolumeUp,
  hardUpWithVolumeDown,
  hardUpWithVolumeSteady,
  hardDown,

  /// The share of easy time (Z1+Z2) of the heart-rate time moved by five
  /// points or more.
  easyShareUp,
  easyShareDown,

  /// Time in Z3 rose or fell by 30 % or more.
  middleUp,
  middleDown,

  /// The heart-rate coverage of the two windows differs a lot, so part of
  /// any change can be missing data.
  coverageChanged,
}

/// The latest 28 days against the 28 days before them.
class HrZoneComparison {
  const HrZoneComparison({
    required this.previousStart,
    required this.recentStart,
    required this.end,
    required this.previous,
    required this.recent,
    required this.observations,
  });

  /// Day boundaries: previous = [previousStart, recentStart), recent =
  /// [recentStart, end).
  final DateTime previousStart, recentStart, end;
  final HrZoneTotals previous, recent;
  final List<HrZoneObservation> observations;

  HrZoneChange get duration =>
      HrZoneChange(previous.elapsedSeconds, recent.elapsedSeconds);
  HrZoneChange get easy =>
      HrZoneChange(previous.easySeconds, recent.easySeconds);
  HrZoneChange get middle =>
      HrZoneChange(previous.middleSeconds, recent.middleSeconds);
  HrZoneChange get hard =>
      HrZoneChange(previous.hardSeconds, recent.hardSeconds);
  HrZoneChange zone(int i) =>
      HrZoneChange(previous.zoneSeconds[i], recent.zoneSeconds[i]);
}

/// Why a planned session's zone time cannot be compared with heart rate.
enum PlanZoneGap {
  /// Targets in power: no documented conversion to heart-rate zones.
  power,

  /// Targets in pace (swimming, CSS): not heart-rate zones.
  pace,

  /// Effort by feel (RPE) or no zone targets in its steps.
  noHrTargets,

  /// Strength and other sessions without heart-rate zones.
  notEndurance,
}

/// One planned session as the comparison sees it.
class PlannedZoneSession {
  const PlannedZoneSession({
    required this.sessionId,
    required this.sport,
    required this.date,
    required this.plannedSeconds,
    this.zoneSeconds,
    this.gap,
    this.done = false,
    this.missed = false,
    this.phase,
  });

  final String sessionId, sport;
  final DateTime date;
  final double plannedSeconds;

  /// Planned seconds in Z1–Z5 from the steps' heart-rate zones; null when the
  /// session is not comparable ([gap] says why).
  final List<double>? zoneSeconds;
  final PlanZoneGap? gap;

  /// Done, or past and not done (missed): a missed session is not zero
  /// intensity, it is not there.
  final bool done, missed;

  /// base, build, peak, taper, recovery, race.
  final String? phase;

  bool get comparable => zoneSeconds != null;
}

/// A zone where planned and recorded time differ by much, relative to the
/// planned week rather than by a fixed universal number.
class PlanZoneDeviation {
  const PlanZoneDeviation(this.zone, this.planned, this.actual);
  final int zone;
  final double planned, actual;
  double get delta => actual - planned;
}

/// Planned against recorded zone time for a week or a block.
class HrZonePlanComparison {
  const HrZonePlanComparison({
    required this.planned,
    required this.actual,
    required this.sessions,
    required this.comparableSessions,
    required this.missedSessions,
    required this.gaps,
    required this.deviations,
  });

  /// Planned seconds per zone of the comparable sessions.
  final List<double> planned;

  /// Recorded seconds per zone in the same days and sports.
  final HrZoneTotals actual;

  /// All planned endurance sessions, and those whose zone time is comparable.
  final int sessions, comparableSessions;

  /// Comparable sessions that were missed: they stay out of the planned
  /// time, so a missed session is not read as easy training.
  final int missedSessions;

  /// Sessions that cannot be compared, by reason.
  final Map<PlanZoneGap, int> gaps;
  final List<PlanZoneDeviation> deviations;

  /// Share of the planned sessions the comparison covers, 0–1.
  double get coverage => sessions > 0 ? comparableSessions / sessions : 0;
}

/// The trends, from workouts the app reads and keeps.
abstract class HrZoneTrends {
  /// Whether this build computes them (FjeliaPro).
  bool get isAvailable;

  /// Bars from [from] to [to] (local days, [to] exclusive), one per day,
  /// week or month; [sport] null for all sports.
  List<HrZonePeriod> periods(
    List<HrZoneWorkout> workouts, {
    required DateTime from,
    required DateTime to,
    required HrZoneGrouping grouping,
    String? sport,
    bool mondayFirst = true,
  });

  /// The latest 28 days up to [today] (included) against the 28 before.
  HrZoneComparison compare28(
    List<HrZoneWorkout> workouts, {
    required DateTime today,
    String? sport,
  });

  /// Planned against recorded from [from] to [to].
  HrZonePlanComparison planVsActual(
    List<PlannedZoneSession> planned,
    List<HrZoneWorkout> workouts, {
    required DateTime from,
    required DateTime to,
    String? sport,
  });

  /// Lines for the AI coach: the 28-day comparison and planned against
  /// recorded, as observations with their evidence; empty when there is
  /// nothing to say.
  List<String> coachContext(
    List<HrZoneWorkout> workouts,
    List<PlannedZoneSession> planned, {
    required DateTime today,
  });
}
