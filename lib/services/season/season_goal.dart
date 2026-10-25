import '../../db/database.dart';
import '../../models/race_profile.dart';
import '../race_predictor.dart';

/// Bumped when the rules below change in a way that changes plans.
const seasonPolicyVersion = 1;

/// Switches the season planner. With it off every plan is built for the
/// plan's own goal alone, as before multi-goal planning; goals, links and the
/// stored season stay, so turning it on again loses nothing.
class SeasonPolicy {
  const SeasonPolicy._();

  static bool multiGoalPlanning = true;
}

/// How much a goal matters. A priority says how the season trades goals off;
/// the date says how urgent it is. Neither replaces the other.
enum GoalPriority {
  a,
  b,
  c;

  static GoalPriority parse(String? raw) => switch (raw?.toLowerCase()) {
    'a' => GoalPriority.a,
    'b' => GoalPriority.b,
    _ => GoalPriority.c,
  };

  /// Share of an event's preparation the season gives it when it competes
  /// with another goal. A product choice, not a physiological constant.
  double get weight => switch (this) {
    GoalPriority.a => 1.0,
    GoalPriority.b => 0.85,
    GoalPriority.c => 0.5,
  };
}

/// Whether the athlete means to be at the start.
enum Participation {
  committed,
  flexible,
  cancelled;

  static Participation parse(String? raw) => switch (raw) {
    'flexible' => Participation.flexible,
    'cancelled' => Participation.cancelled,
    _ => Participation.committed,
  };
}

/// What the athlete wants from the event. Unknown until they say.
enum Ambition {
  finish,
  performance;

  static Ambition? parse(String? raw) => switch (raw) {
    'finish' => Ambition.finish,
    'performance' => Ambition.performance,
    _ => null,
  };
}

/// Whole local calendar days from [a] to [b]. Counts calendar days, so a
/// daylight-saving change cannot make it one off.
int daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

DateTime localDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// What an event asks of the athlete, worked out from its course and target.
///
/// The target time is what the athlete wants; the estimate is what the
/// distance and climbing suggest. They stay apart: a target says nothing
/// about current ability and never becomes a threshold.
class GoalDemand {
  const GoalDemand({
    required this.sport,
    required this.distanceKm,
    this.ascentM,
    this.targetMinutes,
    required this.estimatedMinutes,
  });

  final String sport;
  final double distanceKm;
  final double? ascentM;

  /// The athlete's target time in minutes, when they gave one.
  final double? targetMinutes;

  /// A typical time for the course; used when there is no target.
  final double estimatedMinutes;

  /// Metres climbed per kilometre; null without ascent data.
  double? get climbPerKm => ascentM == null || ascentM! <= 0 || distanceKm <= 0
      ? null
      : ascentM! / distanceKm;

  /// The duration planning works from: the target when there is one, else the
  /// estimate. [durationBasis] says which, so a screen can be honest about it.
  double get planningMinutes => targetMinutes ?? estimatedMinutes;
  String get durationBasis => targetMinutes != null ? 'target' : 'estimate';

  /// Average speed of the target in km/h, when there is one.
  double? get targetSpeedKmh => targetMinutes == null || targetMinutes! <= 0
      ? null
      : distanceKm / (targetMinutes! / 60);

  bool get isRide => sport.startsWith('cycl');
  bool get isFoot =>
      sport == 'running' || sport == 'trail_running' || sport == 'hiking';

  /// Days after the event with no ordinary hard work. Grows with how long the
  /// event takes; a policy, to be tuned with athlete response.
  int get recoveryDays {
    final m = planningMinutes;
    if (m < 60) return 1;
    if (m < 120) return 2;
    if (m < 180) return 3;
    if (m < 270) return 5;
    if (m < 420) return 6;
    return 7;
  }

  /// Days before the event that are sharpening for a goal of [priority].
  int sharpenDays(GoalPriority priority) {
    final m = planningMinutes;
    return switch (priority) {
      GoalPriority.a => m >= 150 ? 14 : 7,
      GoalPriority.b => m >= 150 ? 7 : 4,
      GoalPriority.c => m >= 240 ? 3 : 0,
    };
  }

  /// Whole days after the event on which only easy sessions fit.
  int get easyDaysAfter => (recoveryDays / 2).ceil().clamp(1, 4);
}

/// One race goal as the season planner sees it.
class SeasonGoal {
  const SeasonGoal({
    required this.id,
    required this.name,
    required this.sport,
    required this.date,
    required this.distanceM,
    this.elevationM,
    this.targetSeconds,
    this.priority = GoalPriority.a,
    this.participation = Participation.committed,
    this.ambition,
  });

  factory SeasonGoal.fromRow(RaceGoal row) => SeasonGoal(
    id: row.id,
    name: row.name,
    sport: row.primarySport,
    date: localDay(row.raceDate),
    distanceM: row.distanceM,
    elevationM: row.elevationM,
    targetSeconds: row.targetFinishSeconds,
    priority: GoalPriority.parse(row.priority),
    participation: Participation.parse(row.participation),
    ambition: Ambition.parse(row.ambition),
  );

  final String id;
  final String name;
  final String sport;

  /// The event's local day.
  final DateTime date;
  final double distanceM;
  final double? elevationM;
  final int? targetSeconds;
  final GoalPriority priority;
  final Participation participation;
  final Ambition? ambition;

  bool get isActive => participation != Participation.cancelled;

  RaceProfile get profile => RaceProfile(
    sport: sport,
    distanceM: distanceM,
    elevationM: elevationM,
    targetSeconds: targetSeconds,
  );

  /// Typical seconds per metre by sport, used only to size an event that has
  /// no target.
  static double _typicalSecondsPerMetre(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('cycl')) return 3.6 / 27; // 27 km/h
    if (s.contains('swim')) return 1.4;
    if (s.contains('hik')) return 0.72;
    return 0.36; // 6:00 per km
  }

  GoalDemand get demand {
    final hill = RacePredictor.hillFactor(distanceM, elevationM);
    return GoalDemand(
      sport: sport,
      distanceKm: distanceM / 1000,
      ascentM: elevationM,
      targetMinutes: targetSeconds == null ? null : targetSeconds! / 60,
      estimatedMinutes: distanceM * hill * _typicalSecondsPerMetre(sport) / 60,
    );
  }

  /// The fields that change a plan, in a fixed order.
  String get revisionKey => [
    id,
    priority.name,
    sport,
    '${date.year}-${date.month}-${date.day}',
    distanceM.round(),
    elevationM?.round() ?? '',
    targetSeconds ?? '',
    participation.name,
    ambition?.name ?? '',
  ].join('|');

  /// Short revision of this goal alone.
  String get revision => stableHash(revisionKey);
}

/// A small stable hash (FNV-1a, 32 bit) written in hex. Not for security: it
/// tells whether planning inputs changed.
String stableHash(String input) {
  var h = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}
