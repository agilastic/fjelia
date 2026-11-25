import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../db/database.dart';
import '../services/hr_zone_change_notice.dart';
import '../services/hr_zone_history.dart';
import 'package:fjelia_core/services/hr_zone_model.dart';
import 'package:fjelia_core/utils/log.dart';
import 'database_provider.dart';
import 'user_profile_provider.dart';

/// The athlete's heart-rate zones: the zone history per sport and the
/// zones in force today. Every change goes through the history.
final hrZonesProvider = StateNotifierProvider<HrZonesNotifier, HrZonesState>((
  ref,
) {
  return HrZonesNotifier(
    ref.watch(databaseProvider),
    () async => (await ref.read(userProfileProvider.future)).maxHrEstimate,
  );
});

/// Lower HR bound of zones 1–5.
class HrZones {
  const HrZones(this.bounds);

  final List<int> bounds;

  static HrZones fromJson(String json) => HrZones(
    (jsonDecode(json) as List).map((e) => (e as num).toInt()).toList(),
  );

  String toJson() => jsonEncode(bounds);
}

class HrZonesState {
  HrZonesState({
    required this.running,
    required this.cycling,
    required this.swimming,
    HrZoneBook? book,
    this.conflicts = const {},
    this.estimate,
  }) : book = book ?? HrZoneBook(const []);

  /// The zones in force today.
  final HrZones running;
  final HrZones cycling;
  final HrZones swimming;

  /// Every zone definition over time.
  final HrZoneBook book;

  /// Sports whose zones the older settings stored differently than the
  /// history: those zones, waiting for the athlete to choose.
  final Map<String, List<int>> conflicts;

  /// Karvonen running zones from the resting and maximum heart rate, when
  /// known: the estimate and the check of the zones in use.
  final List<int>? estimate;

  /// The estimate for [sport] (other sports lower by [zoneOffset]).
  List<int>? estimateFor(String sport) {
    final e = estimate;
    if (e == null) return null;
    return sport == 'running' ? e : derivedZones(e, sport);
  }

  HrZones forSport(String sport) => switch (sport) {
    'cycling' => cycling,
    'swimming' => swimming,
    _ => running,
  };

  /// Whether [sport]'s zones look wrong: `cyclingAboveRunning` (cycling
  /// zones should sit about 5 bpm below running), `estimate` (Z2–Z4 more
  /// than 10 bpm from the Karvonen estimate) or null. Only zones the
  /// athlete has, not derived or estimated ones; never changes anything.
  String? check(String sport) {
    final method = book.latest(sport)?.method;
    if (method == null ||
        method == ZoneMethod.derived ||
        method == ZoneMethod.estimate) {
      return null;
    }
    final zones = forSport(sport).bounds;
    if (sport == 'cycling' &&
        [for (var i = 1; i < 4; i++) zones[i] >= running.bounds[i]]
            .every((above) => above)) {
      return 'cyclingAboveRunning';
    }
    final e = estimateFor(sport);
    if (e != null &&
        [for (var i = 1; i < 4; i++) (zones[i] - e[i]).abs() > 10]
            .any((far) => far)) {
      return 'estimate';
    }
    return null;
  }

  /// The zones an activity is measured with: those of its day.
  List<int> forActivity(String type, DateTime start) =>
      book.forActivity(type, start) ??
      forSport(zoneSport(type) ?? 'running').bounds;
}

/// Zones before anything is known: a 45-year-old with a resting heart rate
/// of 60, by Karvonen.
const _defaultRunning = [118, 129, 140, 151, 162];

HrZonesState _fromBook(
  HrZoneBook book,
  Map<String, List<int>> conflicts, {
  List<int>? estimate,
}) {
  final running = book.current('running') ?? _defaultRunning;
  HrZones zones(String sport) =>
      HrZones(book.current(sport) ?? derivedZones(running, sport));
  return HrZonesState(
    running: HrZones(running),
    cycling: zones('cycling'),
    swimming: zones('swimming'),
    book: book,
    conflicts: conflicts,
    estimate: estimate,
  );
}

class HrZonesNotifier extends StateNotifier<HrZonesState> {
  /// Without [db] (tests of a screen): the default zones only.
  HrZonesNotifier([this._db, this._ageEstimate])
    : super(_fromBook(HrZoneBook(const []), const {})) {
    loaded = _load();
  }

  final AppDatabase? _db;
  final Future<int?> Function()? _ageEstimate;

  /// Completes when the stored zones are in [state]. Anything that changes
  /// or reads zones right after startup must wait for it.
  late final Future<void> loaded;

  /// The age-predicted maximum heart rate, read once.
  int? _age;

  static const _storage = FlutterSecureStorage();

  /// The older settings store, before the history was the only one.
  static const _legacyKeys = {
    'running': 'custom_hr_zones_running',
    'cycling': 'custom_hr_zones_cycling',
  };
  static const _legacyBikeFromDevice = 'hr_zones_cycling_from_device';
  static const _conflictsKey = 'hr_zone_conflicts_v1';
  static const _deviceSchemeKey = 'hr_zones_device_lthr_scheme';

  HrZoneHistory? get _history => _db == null ? null : HrZoneHistory(_db);

  Future<void> _load() async {
    final history = _history;
    if (history == null) return;
    try {
      await _migrateLegacy(history);
      try {
        _age = await _ageEstimate?.call();
      } catch (_) {}
      await history.refreshEstimate(ageEstimate: _age);
      await _reload();
    } catch (e) {
      log('[HrZones] not loaded: $e');
    }
  }

  Future<void> _reload() async {
    final history = _history;
    if (history == null || !mounted) return;
    final conflicts = await _conflicts();
    final book = await history.book();
    List<int>? estimate;
    try {
      estimate = await history.estimate(ageEstimate: _age);
    } catch (_) {}
    if (mounted) state = _fromBook(book, conflicts, estimate: estimate);
  }

  Future<Map<String, List<int>>> _conflicts() async {
    final raw = await _storage.read(key: _conflictsKey);
    if (raw == null) return const {};
    return {
      for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries)
        e.key: [for (final v in e.value as List) (v as num).toInt()],
    };
  }

  /// Zones from the older settings store move into the history: as the
  /// first zones when there are none, or, when the history holds others,
  /// as a question for the athlete (neither has a reliable date).
  Future<void> _migrateLegacy(HrZoneHistory history) async {
    final conflicts = {...await _conflicts()};
    var any = false;
    for (final MapEntry(key: sport, value: key) in _legacyKeys.entries) {
      final raw = await _storage.read(key: key);
      if (raw == null) continue;
      any = true;
      final stored = zoneFloorsOf(raw);
      if (stored == null) continue;
      final book = await history.book();
      final own = book.of(sport);
      if (own.isEmpty) {
        await history.record(
          sport,
          stored,
          method: ZoneMethod.initial,
          source: 'settings',
          from: DateTime.fromMillisecondsSinceEpoch(0),
        );
      } else {
        final current = book.current(sport);
        if (current != null && current.join(',') != stored.join(',')) {
          conflicts[sport] = stored;
        }
      }
    }
    if (!any) return;
    if (conflicts.isNotEmpty) {
      await _storage.write(key: _conflictsKey, value: jsonEncode(conflicts));
      log('[HrZones] zone conflict kept for the athlete: $conflicts');
    }
    for (final key in [..._legacyKeys.values, _legacyBikeFromDevice]) {
      await _storage.delete(key: key);
    }
  }

  /// Makes [floors] the zones of [sport] from [from] on (now when null).
  /// With [notify], a change is kept for the zone notice and the coach (the
  /// athlete did not make it).
  Future<void> record(
    String sport,
    List<int> floors, {
    required String method,
    String source = 'fjelia',
    DateTime? from,
    bool notify = false,
  }) async {
    await loaded;
    final before = state.book.at(sport, from ?? DateTime.now());
    // The first measured zones after the estimate are no change to report.
    final latest = state.book.latest('running')?.method;
    final firstReal = latest == null || latest == ZoneMethod.estimate;
    final history = _history;
    if (history == null) {
      // Screen tests without a database: only what is shown changes.
      state = HrZonesState(
        running: sport == 'running' ? HrZones(floors) : state.running,
        cycling: sport == 'cycling' ? HrZones(floors) : state.cycling,
        swimming: sport == 'swimming' ? HrZones(floors) : state.swimming,
        book: state.book,
        conflicts: state.conflicts,
        estimate: state.estimate,
      );
      return;
    }
    if (await history.record(
      sport,
      floors,
      method: method,
      source: source,
      from: from,
    )) {
      log('[HrZones] $sport $floors ($method, from ${from ?? 'now'})');
      if (notify && !firstReal) {
        await HrZoneChangeNotice.add(
          HrZoneChange(
            sport: sport,
            before: before,
            after: floors,
            method: method,
            at: DateTime.now(),
          ),
        );
      }
    }
    await _reload();
  }

  /// The athlete's answer to a conflict: [floors] become the sport's zones
  /// from the start of the zones in force (they replace them).
  Future<void> resolveConflict(String sport, List<int>? floors) async {
    await loaded;
    if (floors != null) {
      final since = state.book.latest(sport)?.effectiveFrom;
      await record(
        sport,
        floors,
        method: ZoneMethod.resolved,
        source: 'athlete',
        from: since,
      );
    }
    final rest = {...state.conflicts}..remove(sport);
    if (rest.isEmpty) {
      await _storage.delete(key: _conflictsKey);
    } else {
      await _storage.write(key: _conflictsKey, value: jsonEncode(rest));
    }
    await _reload();
  }

  /// The zones of [sport] in force today, in force from [from] on instead:
  /// a change dated back, e.g. to the day of a test.
  Future<void> backdate(String sport, DateTime from) async {
    await loaded;
    final latest = state.book.latest(sport);
    final floors = latest == null ? null : zoneFloorsOf(latest.floorsJson);
    if (latest == null || floors == null) return;
    await record(
      sport,
      floors,
      method: latest.method,
      source: latest.source,
      from: from,
    );
  }

  /// Karvonen zones for [maxHr] with the resting heart rate of the last
  /// nights (60 without any).
  Future<List<int>> karvonen(int maxHr) async {
    final rest = await _history?.restingHeartRate() ?? 60;
    return karvonenZones(maxHr: maxHr, restingHr: math.min(rest, maxHr - 60));
  }

  /// The zones in force today for an activity type.
  HrZones zonesFor(String activityType) =>
      state.forSport(zoneSport(activityType) ?? 'running');

  /// The device's own %LTHR scheme (floors + LTHR), used to keep its
  /// percentages when the app detects a new threshold.
  Future<void> saveDeviceScheme(List<int> floors, int lthr) => _storage.write(
    key: _deviceSchemeKey,
    value: jsonEncode({'floors': floors, 'lthr': lthr}),
  );

  Future<({List<int> floors, int lthr})?> deviceScheme() async {
    final raw = await _storage.read(key: _deviceSchemeKey);
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return (
      floors: (m['floors'] as List).map((e) => (e as num).toInt()).toList(),
      lthr: (m['lthr'] as num).toInt(),
    );
  }

  /// LT1 marks the top of zone 2, i.e. the start of zone 3, from the day of
  /// the test ([from]) on.
  Future<void> applyLt1Ceiling(int lt1Bpm, {DateTime? from}) async {
    await loaded;
    final bounds = List<int>.from(
      (from == null ? null : state.book.at('running', from)) ??
          state.running.bounds,
    );
    if (bounds.length < 5) return;
    bounds[2] = lt1Bpm;
    if (bounds[1] >= lt1Bpm) bounds[1] = lt1Bpm - 1;
    if (bounds[3] <= lt1Bpm) bounds[3] = lt1Bpm + 1;
    await record('running', bounds, method: ZoneMethod.lt1, from: from);
  }

  /// Running zones from an app-detected LT2 (= LTHR), from the day of the
  /// test ([from]) on. Keeps the athlete's own %LTHR scheme when one is
  /// known (e.g. from Garmin), else Friel %LTHR zones. A sport without zones
  /// of its own follows by the history's rule; one with its own keeps them.
  Future<void> applyFromLt2Hr(int lt2Bpm, {DateTime? from}) async {
    final scheme = await deviceScheme();
    final run = scheme != null && scheme.lthr > 0
        ? scaleZoneFloors(scheme.floors, from: scheme.lthr, to: lt2Bpm)
        : lthrZoneFloors(lt2Bpm);
    await record('running', run, method: ZoneMethod.lt2, from: from);
  }

  /// Zones set on the athlete's device, per sport; a sport the device has
  /// no zones of its own for is left out (null).
  Future<void> applyDeviceZones({
    List<int>? running,
    List<int>? cycling,
    List<int>? swimming,
    String source = 'device',
  }) async {
    for (final (sport, zones) in [
      ('running', running),
      ('cycling', cycling),
      ('swimming', swimming),
    ]) {
      if (zones == null) continue;
      await record(
        sport,
        zones,
        method: ZoneMethod.device,
        source: source,
        notify: true,
      );
    }
  }

  Future<void> saveRunning(
    HrZones zones, {
    String method = ZoneMethod.manual,
    DateTime? from,
  }) => record('running', zones.bounds, method: method, from: from);

  Future<void> saveCycling(
    HrZones zones, {
    String method = ZoneMethod.manual,
    DateTime? from,
  }) => record('cycling', zones.bounds, method: method, from: from);

  Future<void> saveSwimming(
    HrZones zones, {
    String method = ZoneMethod.manual,
    DateTime? from,
  }) => record('swimming', zones.bounds, method: method, from: from);
}
