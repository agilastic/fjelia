import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../db/database.dart';
import '../models/device_hr_zones.dart';
import '../services/device_threshold_store.dart';
import '../services/device_zone_store.dart';
import '../services/hr_zone_change_notice.dart';
import '../l10n/l10n_ext.dart';
import '../services/threshold_choice_store.dart';
import '../services/source_priority_service.dart';
import '../services/zone_recalculation_service.dart';
import '../utils/log.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'hr_zones_provider.dart';
import 'hrv_reminder_provider.dart' show localNotificationGatewayProvider;
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
/// swimming follow the device when it has zones of their own (and the
/// athlete applied no cycling threshold); its DEFAULT zones only count for
/// running. Every change is a new entry in the zone history.
final hrZoneSyncProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    const store = DeviceZoneStore();
    if (ref.read(authProvider).garminConnected) {
      final garmin = ref.read(garminClientProvider);
      await store.save('garmin_api', await garmin.getHrZoneSettings());
      // Shown as candidates; applied only when the athlete confirms.
      await const DeviceThresholdStore().save(
        await garmin.getDetectedThresholds(),
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
    // A sport's own zones; DEFAULT ones are general (running-like) zones and
    // never count as cycling or swimming zones: those then follow the
    // history's rule from the running zones.
    DeviceHrZones? own(String sport) =>
        settings.where((s) => s.sport == sport).firstOrNull;
    final run = pick('RUNNING');
    final bike = own('CYCLING');
    final swim = own('SWIMMING');
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
    // A threshold the athlete applied from another source (Settings →
    // thresholds) wins over the device, like the app's own LT2 test.
    final applied = await const ThresholdChoiceStore().applied();
    final useDeviceRun = appLt2 == null && runZonesFollowDevice(applied);
    final useDeviceBike = bikeZonesFollowDevice(applied);
    await zones.applyDeviceZones(
      running: useDeviceRun ? run.floors : null,
      cycling: useDeviceBike ? bike?.floors : null,
      swimming: swim?.floors,
      source: source,
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
        thresholdHrCyclingBpm: !useDeviceBike || bike?.lthr == null
            ? const Value.absent()
            : Value(bike!.lthr),
        thresholdHrSwimBpm: swim?.lthr == null
            ? const Value.absent()
            : Value(swim!.lthr),
        maxHrBpm: run.maxHr == null ? const Value.absent() : Value(run.maxHr),
        lastUpdatedAt: Value(DateTime.now()),
      ),
    );
    log(
      '[HrZones] source=$source running: ${useDeviceRun ? '${run.method} lthr=${run.lthr}' : 'app LT2=${appLt2?.lt2Bpm} applied=$applied'} '
      'floors=${ref.read(hrZonesProvider).running.bounds}; cycling: '
      '${bike == null ? 'none of its own' : '${bike.method} floors=${bike.floors}'}',
    );
  },
);

/// Re-scores time-in-zone from HR samples with the zones of each workout's
/// day: the last days after every sync (new workouts), and every workout
/// from the earliest zone change since the last run (a change dated back, a
/// first history). A change from today on rewrites no earlier workout.
final zoneRecalculationProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    const storage = FlutterSecureStorage();
    const key = 'hr_zone_history_seen_v1';
    await ref.read(hrZonesProvider.notifier).loaded;
    final book = ref.read(hrZonesProvider).book;
    if (book.isEmpty) return;
    final seen = int.tryParse(await storage.read(key: key) ?? '') ?? 0;
    final now = DateTime.now();
    var since = now.subtract(const Duration(days: 3));
    final newest = book.definitions.map((d) => d.id).reduce(math.max);
    for (final d in book.definitions) {
      if (d.id > seen && d.effectiveFrom.isBefore(since)) {
        since = d.effectiveFrom;
      }
    }
    // Older workouts have no heart-rate samples worth reading again.
    final oldest = now.subtract(const Duration(days: 400));
    if (since.isBefore(oldest)) since = oldest;
    final updated = await ZoneRecalculationService(ref.read(databaseProvider))
        .recalculate(book: book, since: since);
    await storage.write(key: key, value: '$newest');
    log(
      '[HrZones] time-in-zone recalculated for $updated activities since '
      '${since.toIso8601String().substring(0, 10)}',
    );
  },
);

/// After a sync: the notice of zones the watch changed, when one is due
/// (HrZoneChangeNotice).
final hrZoneNoticeProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () => HrZoneChangeNotice(
        ref.read(databaseProvider),
        ref.read(localNotificationGatewayProvider),
      ).run(tr),
);
