import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';
import 'day_data_provider.dart' show syncStatusListenerProvider;

/// Gear, diary and lab tests from fjelia_views, the same as on the
/// computer. They read again after a sync and after an edit here.

final gearProvider = FutureProvider<List<GearItem>>((ref) {
  ref.watch(syncStatusListenerProvider);
  return loadGear(ref.watch(databaseProvider));
});

final diaryProvider = FutureProvider.family<List<DiaryEntry>, String>((
  ref,
  query,
) {
  ref.watch(syncStatusListenerProvider);
  return loadDiary(ref.watch(databaseProvider), query: query);
});

final labTestsProvider = FutureProvider<List<LabTestItem>>((ref) {
  ref.watch(syncStatusListenerProvider);
  return loadLabTests(ref.watch(databaseProvider));
});

/// The gear an activity counts for.
final activityGearProvider = FutureProvider.family<String?, String>((
  ref,
  activityId,
) {
  ref.watch(gearProvider);
  return gearOfActivity(ref.watch(databaseProvider), activityId);
});

/// Changes to gear and lab tests, for the screens.
final gearEditsProvider = Provider<GearEdits>(
  (ref) => GearEdits(ref.watch(databaseProvider)),
);

final labTestEditsProvider = Provider<LabTestEdits>(
  (ref) => LabTestEdits(ref.watch(databaseProvider)),
);
