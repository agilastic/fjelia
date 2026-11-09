import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sport_stats.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';

/// Running and riding numbers: the last four weeks, this year, all time and
/// the best efforts. Worked out again after a sync brings new activities.
final sportStatsProvider = FutureProvider<Map<StatsSport, SportStats>>((ref) {
  ref.watch(syncStatusListenerProvider);
  return computeSportStats(ref.watch(databaseProvider), DateTime.now());
});
