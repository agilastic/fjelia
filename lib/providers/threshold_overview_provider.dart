import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../l10n/l10n_ext.dart';
import 'package:fjelia_core/models/threshold_candidate.dart';
import '../services/device_threshold_store.dart';
import 'package:fjelia_core/services/dfa_alpha1.dart' show DfaThreshold;
import '../services/dfa_alpha1_service.dart';
import 'package:fjelia_core/services/ramp_test.dart' show rampTestSubType;
import 'package:fjelia_core/services/hr_zone_model.dart';
import '../services/threshold_choice_store.dart';
import 'database_provider.dart';
import 'ftp_provider.dart';
import 'hr_zone_sync_provider.dart';
import 'hr_zones_provider.dart';
import '../services/hr_zone_history.dart' show ZoneMethod;
import 'lt1_drift_provider.dart';
import 'lt2_tt_provider.dart';
import 'planner_providers.dart';
import 'user_profile_provider.dart';

export 'package:fjelia_core/models/threshold_candidate.dart';

/// One threshold: every candidate, the value in use and what is proposed.
class ThresholdRow {
  const ThresholdRow({
    required this.kind,
    required this.candidates,
    this.inUse,
    this.inUsePaceSecPerKm,
    this.best,
    this.proposal,
  });

  final ThresholdKind kind;

  /// Best first (rank, then newest).
  final List<ThresholdCandidate> candidates;
  final int? inUse, inUsePaceSecPerKm;
  final ThresholdCandidate? best, proposal;
}

class ThresholdOverview {
  const ThresholdOverview(this.rows, {this.coachLocked = false});
  final List<ThresholdRow> rows;

  /// A coach manages the thresholds: nothing can be applied here.
  final bool coachLocked;
}

/// Gathers LT1, LT2 (running and cycling) and FTP from the app's tests, the
/// watch platforms, DFA alpha1, the Polar profile and formulas.
final thresholdOverviewProvider = FutureProvider.autoDispose<ThresholdOverview>(
  (ref) async {
    final db = ref.watch(databaseProvider);
    // Recompute after a new test result or FTP.
    ref
      ..watch(lt2TtProvider)
      ..watch(lt1DriftProvider)
      ..watch(ftpProvider);
    final now = DateTime.now();
    final candidates = <ThresholdCandidate>[];
    void add(
      ThresholdKind kind,
      String source,
      int? value, {
      DateTime? date,
      int? pace,
      int? sessions,
      String? note,
    }) {
      if (value == null) return;
      candidates.add(
        ThresholdCandidate(
          kind: kind,
          source: source,
          value: value,
          date: date,
          paceSecPerKm: pace,
          sessions: sessions,
          note: note,
        ),
      );
    }

    // The app's own tests.
    Future<ThresholdRecord?> latest(String source) =>
        (db.select(db.thresholdRecords)
              ..where((t) => t.source.equals(source))
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(1))
            .getSingleOrNull();
    final tt = await latest('tt');
    add(
      ThresholdKind.lt2,
      'tt',
      tt?.lt2Bpm,
      date: tt?.date,
      pace: tt?.lt2PaceSec,
    );
    final drift = await latest('drift');
    add(ThresholdKind.lt1, 'drift', drift?.lt1Bpm, date: drift?.date);

    // Watch platforms and the Polar profile.
    for (final t in (await const DeviceThresholdStore().all()).values) {
      add(ThresholdKind.lt1, t.source, t.lt1Bpm, date: t.date);
      add(
        ThresholdKind.lt2,
        t.source,
        t.lt2Bpm,
        date: t.date,
        pace: t.lt2PaceSecPerKm,
      );
      add(ThresholdKind.lt2Bike, t.source, t.lt2BikeBpm, date: t.date);
      add(ThresholdKind.ftp, t.source, t.ftpWatts, date: t.date);
    }

    // The value in use, the eFTP and the formulas.
    final thresholds = await ref.watch(athleteThresholdsServiceProvider).get();
    add(
      ThresholdKind.ftp,
      'eftp',
      thresholds?.estimatedFtp?.round(),
      date: thresholds?.lastUpdatedAt,
    );
    final lt2InUse = thresholds?.thresholdHrBpm ?? tt?.lt2Bpm;
    final maxHr = (await ref.watch(userProfileProvider.future)).maxHrEstimate;
    if (lt2InUse != null) {
      add(
        ThresholdKind.lt1,
        'formula',
        lt2InUse - 30,
        note: tr.thresholdFormulaLt2,
      );
    } else if (maxHr != null) {
      add(
        ThresholdKind.lt1,
        'formula',
        (maxHr * 0.77).round(),
        note: tr.thresholdFormulaMaxHr,
      );
    }

    await ref.read(hrZonesProvider.notifier).loaded;
    final zones = ref.read(hrZonesProvider);
    final pace = thresholds?.thresholdPaceMps;
    final inUse = {
      ThresholdKind.lt1: zones.running.bounds.length >= 5
          ? zones.running.bounds[2]
          : null,
      ThresholdKind.lt2: lt2InUse,
      ThresholdKind.lt2Bike: thresholds?.thresholdHrCyclingBpm,
      ThresholdKind.ftp:
          thresholds?.ftpWatts ?? thresholds?.estimatedFtp?.round(),
    };

    // DFA alpha1: the median of at least three recent sessions that fit
    // the value in use.
    final dfa = DfaAlpha1Service(db);
    void addDfa(
      ThresholdKind kind,
      List<({DateTime date, double? hrvt1, double? hrvt2})> sessions,
      double? Function(({DateTime date, double? hrvt1, double? hrvt2})) read,
    ) {
      final usable = plausibleDfa(
        sessions.where((s) => read(s) != null).toList(),
        read: (s) => read(s)!,
        inUse: inUse[kind],
      );
      final median = medianOf([for (final s in usable) read(s)!], minimum: 3);
      add(
        kind,
        'dfa',
        median,
        date: usable.firstOrNull?.date,
        sessions: usable.length,
      );
    }

    final runs = await dfa.recent(cycling: false);
    addDfa(ThresholdKind.lt1, runs, (s) => s.hrvt1);
    addDfa(ThresholdKind.lt2, runs, (s) => s.hrvt2);
    addDfa(
      ThresholdKind.lt2Bike,
      await dfa.recent(cycling: true),
      (s) => s.hrvt2,
    );

    // A planned ramp test: one clean test is enough, like the time trial.
    final rampSessions =
        await (db.select(db.trainingSessions)..where(
              (t) =>
                  t.subType.equals(rampTestSubType) &
                  t.status.equals('completed') &
                  t.sessionDate.isBiggerOrEqualValue(
                    now.subtract(const Duration(days: 42)),
                  ),
            ))
            .get();
    final rampDone = <String, TrainingSession>{
      if (rampSessions.isNotEmpty)
        for (final a
            in await (db.select(db.sessionActuals)..where(
                  (t) =>
                      t.sessionId.isIn([for (final r in rampSessions) r.id]) &
                      t.activityId.isNotNull(),
                ))
                .get())
          a.activityId!: rampSessions.firstWhere((r) => r.id == a.sessionId),
    };
    final rampTaken = <ThresholdKind>{};
    for (final e
        in rampDone.entries.toList()..sort(
          (a, b) => b.value.sessionDate.compareTo(a.value.sessionDate),
        )) {
      final result = await dfa.load(e.key);
      if (result == null || !result.progression) continue;
      final cycling = e.value.sport.startsWith('cycl');
      void take(ThresholdKind kind, DfaThreshold? t, {bool pace = false}) {
        if (t == null || !rampTaken.add(kind)) return;
        final speed = t.speed;
        add(
          kind,
          'dfa_ramp',
          t.heartRate.round(),
          date: e.value.sessionDate,
          pace: pace && speed != null && speed > 0
              ? (1000 / speed).round()
              : null,
        );
      }

      if (cycling) {
        take(ThresholdKind.lt2Bike, result.hrvt2);
      } else {
        take(ThresholdKind.lt1, result.hrvt1);
        take(ThresholdKind.lt2, result.hrvt2, pace: true);
      }
    }

    final kept = await const ThresholdChoiceStore().kept();
    return ThresholdOverview([
      for (final kind in ThresholdKind.values)
        () {
          final own = candidates.where((c) => c.kind == kind).toList()
            ..sort((a, b) {
              final byRank = a.rank.compareTo(b.rank);
              return byRank != 0
                  ? byRank
                  : (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0));
            });
          return ThresholdRow(
            kind: kind,
            candidates: own,
            inUse: inUse[kind],
            inUsePaceSecPerKm:
                kind == ThresholdKind.lt2 && pace != null && pace > 0
                ? (1000 / pace).round()
                : null,
            best: bestThreshold(own, now),
            proposal: thresholdProposal(
              candidates: own,
              inUse: inUse[kind],
              kept: kept,
              now: now,
            ),
          );
        }(),
    ], coachLocked: thresholds?.coachLocked ?? false);
  },
);

final thresholdActionsProvider = Provider<ThresholdActions>(
  ThresholdActions.new,
);

class ThresholdActions {
  ThresholdActions(this.ref);
  final Ref ref;

  /// Makes [c] the value in use: zones, the athlete's thresholds and with
  /// them the training plan. Remembered, so a device sync doesn't undo it.
  Future<void> apply(ThresholdCandidate c) async {
    final service = ref.read(athleteThresholdsServiceProvider);
    if ((await service.get())?.coachLocked ?? false) {
      throw StateError(tr.thresholdsCoachLocked);
    }
    final zones = ref.read(hrZonesProvider.notifier);
    await zones.loaded;
    switch (c.kind) {
      case ThresholdKind.lt1:
        // The zone history keeps the athlete thresholds' copy.
        await zones.applyLt1Ceiling(c.value);
        await service.save(
          AthleteThresholdsCompanion(lastUpdatedAt: Value(DateTime.now())),
        );
      case ThresholdKind.lt2:
        // New zones from LTHR move the top of zone 2; an LT1 the athlete
        // applied stays where it was.
        final lt1Applied =
            (await const ThresholdChoiceStore().applied())[ThresholdKind.lt1] !=
            null;
        final lt1 = ref.read(hrZonesProvider).running.bounds;
        final keptLt1 = lt1Applied && lt1.length >= 5 ? lt1[2] : null;
        await zones.applyFromLt2Hr(c.value);
        if (keptLt1 != null && keptLt1 < c.value) {
          await zones.applyLt1Ceiling(keptLt1);
        }
        final pace = c.paceSecPerKm;
        await service.save(
          AthleteThresholdsCompanion(
            thresholdHrBpm: Value(c.value),
            thresholdPaceMps: pace != null && pace > 0
                ? Value(1000 / pace)
                : const Value.absent(),
            lastUpdatedAt: Value(DateTime.now()),
          ),
        );
      case ThresholdKind.lt2Bike:
        await zones.saveCycling(
          HrZones(lthrZoneFloors(c.value, cycling: true)),
          method: ZoneMethod.lt2Bike,
        );
        await service.save(
          AthleteThresholdsCompanion(
            thresholdHrCyclingBpm: Value(c.value),
            lastUpdatedAt: Value(DateTime.now()),
          ),
        );
      case ThresholdKind.ftp:
        await ref.read(ftpProvider.notifier).saveManual(c.value);
    }
    await const ThresholdChoiceStore().markApplied(c);
    if (c.kind != ThresholdKind.ftp) {
      await ref.read(zoneRecalculationProvider)();
    }
    ref.invalidate(thresholdOverviewProvider);
  }

  /// Keeps the value in use; [c] is not proposed again until it changes.
  Future<void> keep(ThresholdCandidate c) async {
    await const ThresholdChoiceStore().keep(c);
    ref.invalidate(thresholdOverviewProvider);
  }
}
