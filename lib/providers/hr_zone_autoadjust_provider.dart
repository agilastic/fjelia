import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';
import 'user_profile_provider.dart';

/// Max HR observed in training (95th percentile of activity max HRs).
class HrAutoAdjustSuggestion {
  const HrAutoAdjustSuggestion({this.runningMaxHr, this.cyclingMaxHr});

  final int? runningMaxHr;
  final int? cyclingMaxHr;
}

final hrAutoAdjustProvider = FutureProvider<HrAutoAdjustSuggestion?>((
  ref,
) async {
  final db = ref.read(databaseProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final activities = await db.getActivitiesInRange(180);

  final run = <double>[];
  final bike = <double>[];
  for (final a in activities) {
    final max = a.maxHeartRate;
    if (max == null || max < 100 || max > 230) continue;
    final t = a.type.toLowerCase();
    if (t.contains('cycl') || t.contains('bike') || t.contains('bik')) {
      bike.add(max);
    } else if (t.contains('run') ||
        t.contains('trail') ||
        t.contains('treadmill')) {
      run.add(max);
    }
  }

  int? p95(List<double> values) {
    if (values.length < 3) return null;
    values.sort();
    return values[((values.length - 1) * 0.95).round()].round();
  }

  var runMax = p95(run);
  var bikeMax = p95(bike);
  // Without ride data, cycling max HR sits ~3 % under running.
  bikeMax ??= runMax == null ? null : (runMax * 0.97).round();
  runMax ??= profile?.maxHrEstimate;
  if (runMax == null && bikeMax == null) return null;
  return HrAutoAdjustSuggestion(runningMaxHr: runMax, cyclingMaxHr: bikeMax);
});
