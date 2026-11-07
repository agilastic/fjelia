import '../../db/database.dart';
import '../post_workout_scorer.dart';

/// What a session asks of the body, or what a workout gave it: its minutes,
/// and its minutes at tempo (zone 3) or harder and at threshold (zone 4) or
/// harder. Planned and done are measured the same way, so one can be
/// compared with the other.
class Stimulus {
  const Stimulus({
    required this.minutes,
    required this.z3Min,
    required this.z4Min,
    this.zonesKnown = true,
  });

  final double minutes, z3Min, z4Min;

  /// False for a workout without heart-rate zones: its intensity is unknown.
  final bool zonesKnown;

  factory Stimulus.planned(TrainingSession s) {
    final m = s.plannedDurationMin.toDouble();
    final dist = PostWorkoutScorer.plannedZoneDistribution(s.plannedZonesJson);
    if (dist != null) {
      double from(int i) => dist.skip(i).fold(0.0, (a, b) => a + b);
      return Stimulus(minutes: m, z3Min: m * from(2), z4Min: m * from(3));
    }
    // Without a zone split: the main zone holds about a third of the time,
    // the rest is warm-up, recoveries and cool-down.
    return switch (s.primaryZone) {
      >= 4 => Stimulus(minutes: m, z3Min: m * .35, z4Min: m * .35),
      3 => Stimulus(minutes: m, z3Min: m * .4, z4Min: 0),
      _ => Stimulus(minutes: m, z3Min: 0, z4Min: 0),
    };
  }

  /// From a workout and its seconds in each zone (see
  /// [PostWorkoutScorer.zoneSeconds]).
  factory Stimulus.done(ActivityRecord a, List<double> zoneSec) {
    final total = zoneSec.fold(0.0, (a, b) => a + b);
    double from(int i) => zoneSec.skip(i).fold(0.0, (a, b) => a + b) / 60;
    return Stimulus(
      minutes: a.durationSeconds / 60,
      z3Min: from(2),
      z4Min: from(3),
      zonesKnown: total > 0,
    );
  }

  /// Easy, tempo or hard, by the minutes at zone 3 and zone 4 or harder.
  int get level => z4Min >= 10
      ? 2
      : z3Min >= 10
      ? 1
      : 0;

  /// At least what [planned] asks: 90 % of its time and 80 % of its minutes
  /// at tempo and at threshold. Without zones only an easy session counts.
  bool covers(Stimulus planned) =>
      minutes >= planned.minutes * .9 &&
      (zonesKnown
          ? z3Min >= planned.z3Min * .8 && z4Min >= planned.z4Min * .8
          : planned.level == 0);

  /// Much the same session: 82–118 % of its time, intensity at most one
  /// level apart (or unknown).
  bool resembles(Stimulus planned) {
    if (planned.minutes <= 0) return false;
    final ratio = minutes / planned.minutes;
    if (ratio < .82 || ratio > 1.18) return false;
    return !zonesKnown || (level - planned.level).abs() <= 1;
  }
}

/// Whether [type] is a ride or a run, the sports that load the legs.
bool isRideType(String type) {
  final t = type.toLowerCase();
  return t.contains('cycl') || t.contains('bik') || t.contains('ride');
}

bool isRunType(String type) {
  final t = type.toLowerCase();
  return t.contains('run') || t.contains('trail');
}

/// A ride or run that leaves the legs tired for the next day: long, or with
/// a good part at threshold or harder.
bool loadsLegs(ActivityRecord a, Stimulus s) {
  if (isRunType(a.type)) return s.minutes >= 90 || s.z4Min >= 20;
  if (isRideType(a.type)) return s.minutes >= 150 || s.z4Min >= 20;
  return false;
}

/// A hard climb: at least 90 minutes of riding or running with 20 minutes at
/// threshold or harder, or steep throughout at tempo. It works the legs as a
/// strength-endurance session does; it is no core or upper-body work.
bool worksLegStrength(ActivityRecord a, Stimulus s) {
  final ride = isRideType(a.type), run = isRunType(a.type);
  if (!(ride || run) || s.minutes < 90 || !s.zonesKnown) return false;
  final km = (a.distanceMeters ?? 0) / 1000;
  final climb = km > 0 ? (a.totalElevation ?? 0) / km : 0.0;
  return s.z4Min >= 20 || (climb >= (ride ? 12 : 30) && s.z3Min >= 30);
}
