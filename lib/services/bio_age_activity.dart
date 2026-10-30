import 'dart:math' as math;

/// A walking-time assumption, not a measured cadence or proof of intensity.
/// CADENCE-Adults: https://pubmed.ncbi.nlm.nih.gov/33168018/
const bioAgeWalkingStepsPerMinute = 100.0;
const bioAgeActivityWindowDays = 7;

class BioAgeActivityDay {
  const BioAgeActivityDay({
    required this.date,
    this.reportedMinutes,
    this.steps,
  });

  final DateTime date;
  final double? reportedMinutes;
  final int? steps;
}

/// Keeps recorded moderate minutes and estimated walking time distinguishable.
/// A date contributes one source: reported minutes (including zero), otherwise
/// steps / 100. Missing dates are unknown, rather than sedentary days.
class BioAgeActivity {
  const BioAgeActivity._({
    this.reportedMinutes = 0,
    this.estimatedWalkingMinutes = 0,
    this.reportedDays = 0,
    this.stepEstimatedDays = 0,
  });

  factory BioAgeActivity.fromDays(
    Iterable<BioAgeActivityDay> days, {
    required DateTime today,
  }) {
    final end = DateTime(today.year, today.month, today.day);
    final start = DateTime(end.year, end.month, end.day - 6);
    final minutesByDay = <DateTime, double>{};
    final stepsByDay = <DateTime, int>{};
    for (final day in days) {
      final date = DateTime(day.date.year, day.date.month, day.date.day);
      if (date.isBefore(start) || date.isAfter(end)) continue;
      final minutes = day.reportedMinutes;
      if (_usable(minutes)) {
        // Daily totals and duplicate snapshots must not be added together.
        minutesByDay[date] = math.max(minutesByDay[date] ?? 0, minutes!);
      }
      final steps = day.steps;
      if (steps != null && steps >= 0) {
        stepsByDay[date] = math.max(stepsByDay[date] ?? 0, steps);
      }
    }

    var estimated = 0.0;
    var estimatedDays = 0;
    for (final entry in stepsByDay.entries) {
      if (minutesByDay.containsKey(entry.key)) continue;
      estimated += entry.value / bioAgeWalkingStepsPerMinute;
      estimatedDays++;
    }
    return BioAgeActivity._(
      reportedMinutes: minutesByDay.values.fold(
        0.0,
        (sum, value) => sum + value,
      ),
      estimatedWalkingMinutes: estimated,
      reportedDays: minutesByDay.length,
      stepEstimatedDays: estimatedDays,
    );
  }

  /// Compatibility for callers supplying an already aggregated week. An
  /// average step count only substitutes for an absent weekly minutes value.
  factory BioAgeActivity.fromWeekly({double? minutes, double? dailySteps}) {
    if (_usable(minutes)) {
      return BioAgeActivity._(
        reportedMinutes: minutes!,
        reportedDays: bioAgeActivityWindowDays,
      );
    }
    if (_usable(dailySteps)) {
      return BioAgeActivity._(
        estimatedWalkingMinutes:
            dailySteps! *
            bioAgeActivityWindowDays /
            bioAgeWalkingStepsPerMinute,
        stepEstimatedDays: bioAgeActivityWindowDays,
      );
    }
    return const BioAgeActivity._();
  }

  final double reportedMinutes;
  final double estimatedWalkingMinutes;
  final int reportedDays, stepEstimatedDays;

  int get coveredDays => reportedDays + stepEstimatedDays;
  int get missingDays => bioAgeActivityWindowDays - coveredDays;
  bool get isComplete => missingDays == 0;
  bool get usesStepEstimate => stepEstimatedDays > 0;

  /// Do not interpret a partially imported week as a full inactive week.
  double? get minutesForScore =>
      isComplete ? reportedMinutes + estimatedWalkingMinutes : null;

  static bool _usable(double? value) =>
      value != null && value.isFinite && value >= 0;
}
