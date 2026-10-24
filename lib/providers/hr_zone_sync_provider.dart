import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../db/database.dart';
import '../models/device_hr_zones.dart';
import '../services/device_zone_store.dart';
import '../services/source_priority_service.dart';
import '../services/zone_recalculation_service.dart';
import '../utils/log.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'hr_zones_provider.dart';
import 'planner_providers.dart';

/// Applies the athlete's device HR zones (display, load, planner targets).
///
/// Every platform's zones land in one store ([DeviceZoneStore]): Garmin's
/// are fetched here on each sync, Polar's arrive with its exercises. The
/// zones used come from the highest-priority activity source (Settings →
/// source priority) that reported any.
///
/// Precedence: the device's running zones/LTHR apply until the app detects
/// LT2 itself (30-min time trial); from then on the app's LTHR drives
/// running zones, scaled with the device's %LTHR percentages. Cycling and
/// swimming always follow the device, as the app does not detect them.
final hrZoneSyncProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    const store = DeviceZoneStore();
    if (ref.read(authProvider).garminConnected) {
      await store.save(
        'garmin_api',
        await ref.read(garminClientProvider).getHrZoneSettings(),
      );
    }
    final all = await store.all();
    if (all.isEmpty) return;
    final priority = await priorityForGroup(SourceGroup.activity);
    final source = [
      ...priority,
      ...all.keys,
    ].firstWhere((s) => all[s]?.isNotEmpty ?? false);
    final settings = all[source]!;

    DeviceHrZones pick(String sport) => settings.firstWhere(
      (s) => s.sport == sport,
      orElse: () => settings.firstWhere(
        (s) => s.sport == 'DEFAULT',
        orElse: () => settings.first,
      ),
    );
    final run = pick('RUNNING');
    final bike = pick('CYCLING');
    final swim = pick('SWIMMING');
    final db = ref.read(databaseProvider);
    final appLt2 =
        await (db.select(db.thresholdRecords)
              ..where((t) => t.source.equals('tt') & t.lt2Bpm.isNotNull())
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(1))
            .getSingleOrNull();

    final zones = ref.read(hrZonesProvider.notifier);
    await zones.loaded;
    if (run.isLthrBased && run.lthr != null) {
      await zones.saveDeviceScheme(run.floors, run.lthr!);
    }
    final useDeviceRun = appLt2 == null;
    await zones.applyDeviceZones(
      running: useDeviceRun
          ? run.floors
          : ref.read(hrZonesProvider).running.bounds,
      cycling: bike.floors,
    );

    final thresholds = ref.read(athleteThresholdsServiceProvider);
    final current = await thresholds.get();
    if (current?.coachLocked ?? false) {
      log('[HrZones] thresholds coach-locked — zones not written');
      return;
    }
    await thresholds.save(
      AthleteThresholdsCompanion(
        thresholdHrBpm: useDeviceRun && run.lthr != null
            ? Value(run.lthr)
            : const Value.absent(),
        runHrZonesJson: Value(
          jsonEncode(
            useDeviceRun
                ? run.floors
                : ref.read(hrZonesProvider).running.bounds,
          ),
        ),
        thresholdHrCyclingBpm: bike.lthr == null
            ? const Value.absent()
            : Value(bike.lthr),
        bikeHrZonesJson: Value(jsonEncode(bike.floors)),
        thresholdHrSwimBpm: swim.lthr == null
            ? const Value.absent()
            : Value(swim.lthr),
        swimHrZonesJson: Value(jsonEncode(swim.floors)),
        maxHrBpm: run.maxHr == null ? const Value.absent() : Value(run.maxHr),
        lastUpdatedAt: Value(DateTime.now()),
      ),
    );
    log(
      '[HrZones] source=$source running: ${useDeviceRun ? '${run.method} lthr=${run.lthr}' : 'app LT2=${appLt2.lt2Bpm}'} '
      'floors=${ref.read(hrZonesProvider).running.bounds}; cycling: ${bike.method} '
      'floors=${bike.floors}',
    );
  },
);

/// Re-scores time-in-zone from HR samples with the current zones: all
/// activities of the last year when the zones changed, else the last days.
final zoneRecalculationProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    const storage = FlutterSecureStorage();
    const key = 'hr_zone_fingerprint_v1';
    await ref.read(hrZonesProvider.notifier).loaded;
    final zones = ref.read(hrZonesProvider);
    final fingerprint = jsonEncode([
      zones.running.bounds,
      zones.cycling.bounds,
    ]);
    final changed = await storage.read(key: key) != fingerprint;
    final now = DateTime.now();
    final updated = await ZoneRecalculationService(ref.read(databaseProvider))
        .recalculate(
          running: zones.running.bounds,
          cycling: zones.cycling.bounds,
          since: now.subtract(Duration(days: changed ? 400 : 3)),
        );
    await storage.write(key: key, value: fingerprint);
    log(
      '[HrZones] time-in-zone recalculated for $updated activities '
      '(${changed ? 'zones changed — full year' : 'recent'})',
    );
  },
);
