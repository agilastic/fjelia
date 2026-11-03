import 'package:drift/native.dart';
import 'package:fjelia/api/garmin_client.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/garmin_data.dart';
import 'package:fjelia/providers/auth_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Garmin account with two runs a month ago, signed in.
class _Garmin extends GarminClient {
  final detailsAsked = <String>[];
  final start = DateTime.now().subtract(const Duration(days: 30));

  @override
  Future<bool> get isLoggedIn async => true;

  @override
  Future<List<GarminActivity>> getActivities({
    int limit = 20,
    int start = 0,
  }) async => start > 0
      ? const []
      : [
          for (final id in ['G1', 'G2'])
            GarminActivity(
              id: id,
              name: 'Run $id',
              type: 'running',
              startTime: this.start,
              duration: const Duration(minutes: 50),
              distanceMeters: 10000,
            ),
        ];

  @override
  Future<
    ({
      Map<String, double>? hrZones,
      List<ActivitySample>? samples,
      double? totalElevation,
      List<LatLng>? trackPoints,
    })
  >
  getActivityDetails(String activityId) async {
    detailsAsked.add(activityId);
    return (
      hrZones: null,
      samples: [
        ActivitySample(distanceMeters: 0, heartRate: 140, timestamp: start),
      ],
      totalElevation: null,
      trackPoints: null,
    );
  }
}

void main() {
  test(
    'Garmin skips a deleted activity and fetches it again on restore',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final db = AppDatabase(NativeDatabase.memory());
      final garmin = _Garmin();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          garminClientProvider.overrideWithValue(garmin),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final sync = container.read(syncServiceProvider);

      // G1 was synced once and then deleted by the athlete.
      expect(await sync.refetchGarminActivity('G1', garmin.start), isTrue);
      await db.deleteActivityByUser('G1');
      garmin.detailsAsked.clear();

      // A later sync of G2 neither stores nor downloads G1.
      expect(await sync.refetchGarminActivity('G2', garmin.start), isTrue);
      expect(garmin.detailsAsked, ['G2']);
      expect(await db.getActivityById('G1'), isNull);
      expect(await db.getActivityById('G2'), isNotNull);

      // Restored: it comes back from its summary, then Garmin sends its curves.
      final back = (await db.restoreDeletedActivity('G1'))!;
      expect(back.metricsJson, isNull);
      expect(await sync.refetchGarminActivity('G1', garmin.start), isTrue);
      expect(garmin.detailsAsked, ['G2', 'G1']);
      expect(
        (await db.getActivityById('G1'))!.metricsJson,
        contains('"hr":140'),
      );
    },
  );
}
