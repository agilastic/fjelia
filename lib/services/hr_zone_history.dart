import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../db/database.dart';

/// The sports with their own heart-rate zones.
const zoneSports = ['running', 'cycling', 'swimming'];

/// The zones' sport family of an activity type: `running`, `cycling`,
/// `swimming`, `other` (an endurance sport without zones of its own) or null
/// for none (strength, yoga, sleep).
String? zoneFamily(String type) {
  final t = type.toLowerCase();
  if (t.contains('swim')) return 'swimming';
  if (t.contains('cycl') ||
      t.contains('bik') ||
      t.contains('ride') ||
      t.contains('spin')) {
    return 'cycling';
  }
  if (t.contains('run') ||
      t.contains('trail') ||
      t.contains('treadmill') ||
      t.contains('hik') ||
      t.contains('walk')) {
    return 'running';
  }
  if (t.contains('strength') || t.contains('yoga') || t.contains('sleep')) {
    return null;
  }
  return 'other';
}

/// The zones an activity type is measured with: its own sport's, the
/// running zones for other endurance sports, null for none.
String? zoneSport(String type) => switch (zoneFamily(type)) {
  'other' => 'running',
  final f => f,
};

/// How much lower than the running zones a sport's zones sit when it has
/// none of its own: a ride runs about 5, a swim about 10 beats lower.
const zoneOffset = {'cycling': 5, 'swimming': 10};

/// Zones of [sport] derived from the running zones by [zoneOffset].
List<int> derivedZones(List<int> running, String sport) => [
  for (final f in running) f - (zoneOffset[sport] ?? 0),
];

/// Five lower bounds, also from the older four upper bounds of Z1–Z4.
List<int>? zoneFloorsOf(String json) {
  try {
    final v = [for (final x in jsonDecode(json) as List) (x as num).round()];
    if (v.length >= 5) return v.sublist(0, 5);
    if (v.length == 4) return [0, v[0] + 1, v[1] + 1, v[2] + 1, v[3] + 1];
  } catch (_) {}
  return null;
}

/// Running zones by Karvonen (heart-rate reserve): Z1–Z5 start at 50, 60,
/// 70, 80 and 90 % of the reserve above the resting heart rate.
List<int> karvonenZones({required int maxHr, required int restingHr}) {
  final reserve = maxHr - restingHr;
  return [
    for (final f in const [.5, .6, .7, .8, .9])
      (restingHr + f * reserve).round(),
  ];
}

/// How a definition came about (column `method`).
abstract final class ZoneMethod {
  /// The zones in force when the history began, for every earlier workout.
  static const initial = 'initial';

  /// Set by the athlete in Settings.
  static const manual = 'manual';

  /// From the athlete's device (Garmin, Polar…).
  static const device = 'device';

  /// From a threshold: LT1, LT2 (running) or the cycling LT2.
  static const lt1 = 'lt1', lt2 = 'lt2', lt2Bike = 'lt2_bike';

  /// From the running zones, for a sport without zones of its own.
  static const derived = 'derived';

  /// Karvonen from resting and maximum heart rate, until anything better.
  static const estimate = 'estimate';

  /// The athlete's answer when two stored zone sets disagreed.
  static const resolved = 'resolved';

  /// Older rows of the first zone history.
  static const settings = 'settings';
}

/// The athlete's heart-rate zones over time, per sport: what was in force on
/// any day. Read-only; [HrZoneHistory] writes it.
class HrZoneBook {
  HrZoneBook(Iterable<HrZoneDefinition> definitions)
    : definitions = [...definitions]
        ..sort((a, b) {
          final c = a.effectiveFrom.compareTo(b.effectiveFrom);
          return c != 0 ? c : a.id.compareTo(b.id);
        });

  /// Oldest first; on the same moment, the later entry wins.
  final List<HrZoneDefinition> definitions;

  bool get isEmpty => definitions.isEmpty;

  List<HrZoneDefinition> of(String sport) => [
    for (final d in definitions)
      if (d.sport == sport) d,
  ];

  /// The definition of [sport] in force at [at]: the latest one from before
  /// it, or the earliest when [at] is older than all of them.
  HrZoneDefinition? definitionAt(String sport, DateTime at) {
    final all = of(sport);
    if (all.isEmpty) return null;
    return all.lastWhere(
      (d) => !d.effectiveFrom.isAfter(at),
      orElse: () => all.first,
    );
  }

  HrZoneDefinition? latest(String sport) => of(sport).lastOrNull;

  /// The zones of [sport] at [at]; a sport without any falls back to the
  /// running zones of that day, lowered by [zoneOffset].
  List<int>? at(String sport, DateTime at) {
    final own = definitionAt(sport, at);
    if (own != null) return zoneFloorsOf(own.floorsJson);
    if (sport == 'running') return null;
    final running = this.at('running', at);
    return running == null ? null : derivedZones(running, sport);
  }

  List<int>? current(String sport) => at(sport, DateTime.now());

  /// The zones an activity of [type] that started at [start] is measured
  /// with, or null for a type without zones or no zones at all.
  List<int>? forActivity(String type, DateTime start) {
    final sport = zoneSport(type);
    return sport == null ? null : at(sport, start);
  }

  /// [sport] has zones of its own, not ones derived from running.
  bool hasOwn(String sport) {
    final method = latest(sport)?.method;
    return method != null && method != ZoneMethod.derived;
  }
}

/// The one place that writes heart-rate zones: a new definition per change,
/// in force from its moment on. The athlete thresholds keep a copy of the
/// zones in force today, for the plan.
class HrZoneHistory {
  HrZoneHistory(this._db);
  final AppDatabase _db;

  Future<HrZoneBook> book() async =>
      HrZoneBook(await _db.select(_db.hrZoneDefinitions).get());

  /// Makes [floors] the zones of [sport] from [from] on (now when null).
  /// Nothing happens when they are the zones in force then already. Running
  /// zones carry over to a sport without zones of its own. A change dated
  /// back has the time in zones from then on worked out again. Returns
  /// whether anything changed.
  Future<bool> record(
    String sport,
    List<int> floors, {
    required String method,
    String source = 'fjelia',
    DateTime? from,
  }) async {
    if (floors.length != 5 || !zoneSports.contains(sport)) return false;
    final when = from ?? DateTime.now();
    final changed = await _db.transaction(() async {
      final before = await book();
      if (!_write(before, sport, floors, method, source, when)) return false;
      await _insert(sport, floors, method, source, when);
      if (sport == 'running') {
        for (final other in const ['cycling', 'swimming']) {
          if (before.hasOwn(other)) continue;
          await _insert(
            other,
            derivedZones(floors, other),
            ZoneMethod.derived,
            source,
            when,
          );
        }
      }
      return true;
    });
    if (!changed) return false;
    if (when.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      await _forgetSummariesSince(sport, when);
    }
    await mirror();
    return true;
  }

  bool _write(
    HrZoneBook book,
    String sport,
    List<int> floors,
    String method,
    String source,
    DateTime when,
  ) {
    final own = book.definitionAt(sport, when);
    // The same zones again change nothing, unless the derived ones become
    // the sport's own.
    if (own == null) return true;
    final same = _same(zoneFloorsOf(own.floorsJson), floors);
    return !same ||
        (own.method == ZoneMethod.derived && method != ZoneMethod.derived) ||
        own.effectiveFrom.isAfter(when);
  }

  static bool _same(List<int>? a, List<int> b) =>
      a != null &&
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

  Future<void> _insert(
    String sport,
    List<int> floors,
    String method,
    String source,
    DateTime when,
  ) => _db
      .into(_db.hrZoneDefinitions)
      .insert(
        HrZoneDefinitionsCompanion.insert(
          sport: sport,
          floorsJson: jsonEncode(floors),
          method: method,
          source: source,
          effectiveFrom: when,
        ),
      );

  /// The kept time in zones of the workouts from [when] on were worked out
  /// with the zones before the change: they are worked out again.
  Future<void> _forgetSummariesSince(String sport, DateTime when) async {
    final families = sport == 'running'
        ? const ['running', 'other', 'cycling', 'swimming']
        : [sport];
    await (_db.delete(_db.hrZoneSummaries)..where(
          (t) =>
              t.sport.isIn(families) & t.startDate.isBiggerOrEqualValue(when),
        ))
        .go();
  }

  /// Keeps the athlete thresholds' copy at the zones in force today.
  Future<void> mirror() async {
    final b = await book();
    String? json(String sport) {
      final z = b.current(sport);
      return z == null ? null : jsonEncode(z);
    }

    final run = json('running'),
        bike = json('cycling'),
        swim = json('swimming');
    if (run == null && bike == null && swim == null) return;
    await _db
        .into(_db.athleteThresholds)
        .insertOnConflictUpdate(
          AthleteThresholdsCompanion(
            athleteId: const Value('self'),
            runHrZonesJson: run == null ? const Value.absent() : Value(run),
            bikeHrZonesJson: bike == null ? const Value.absent() : Value(bike),
            swimHrZonesJson: swim == null ? const Value.absent() : Value(swim),
          ),
        );
  }

  /// The athlete's maximum heart rate: the device's, else the second
  /// highest of the recorded workouts (one spike is not a maximum), else
  /// [ageEstimate].
  Future<int?> maxHeartRate({int? ageEstimate}) async {
    final thresholds = await (_db.select(
      _db.athleteThresholds,
    )..where((t) => t.athleteId.equals('self'))).getSingleOrNull();
    final device = thresholds?.maxHrBpm;
    if (device != null && device >= 120 && device <= 230) return device;
    final rows =
        await (_db.selectOnly(_db.activityRecords)
              ..addColumns([_db.activityRecords.maxHeartRate])
              ..where(
                _db.activityRecords.maxHeartRate.isBetweenValues(120, 230) &
                    _db.activityRecords.startDate.isBiggerOrEqualValue(
                      DateTime.now().subtract(const Duration(days: 730)),
                    ),
              )
              ..orderBy([OrderingTerm.desc(_db.activityRecords.maxHeartRate)])
              ..limit(2))
            .get();
    final observed = [
      for (final r in rows) r.read(_db.activityRecords.maxHeartRate)!.round(),
    ];
    if (observed.length == 2) {
      final best = observed[1];
      // An age-predicted maximum far above anything run shows a low value
      // from easy training only: then the formula is closer.
      if (ageEstimate == null || best >= ageEstimate - 10) return best;
    }
    return ageEstimate;
  }

  /// The median resting heart rate of the last 14 nights.
  Future<int?> restingHeartRate() async {
    final rows =
        await (_db.select(_db.hrvRecords)..where(
              (t) =>
                  t.restingHeartRate.isNotNull() &
                  t.date.isBiggerOrEqualValue(
                    DateTime.now().subtract(const Duration(days: 14)),
                  ),
            ))
            .get();
    final values = [
      for (final r in rows)
        if (r.restingHeartRate! >= 30 && r.restingHeartRate! <= 100)
          r.restingHeartRate!,
    ]..sort();
    if (values.length < 3) return null;
    return values[values.length ~/ 2];
  }

  /// Karvonen running zones from what is known, or null without a maximum.
  Future<List<int>?> estimate({int? ageEstimate}) async {
    final max = await maxHeartRate(ageEstimate: ageEstimate);
    if (max == null) return null;
    final rest = await restingHeartRate() ?? 60;
    if (max - rest < 60) return null;
    return karvonenZones(maxHr: max, restingHr: math.min(rest, max - 60));
  }

  /// Without measured or device zones: the estimate is the running zones,
  /// renewed when it moved by 3 bpm or more and the last one is a month
  /// old. Returns whether it changed.
  Future<bool> refreshEstimate({int? ageEstimate}) async {
    final b = await book();
    final last = b.latest('running');
    if (last != null && last.method != ZoneMethod.estimate) return false;
    final zones = await estimate(ageEstimate: ageEstimate);
    if (zones == null) return false;
    if (last != null) {
      final before = zoneFloorsOf(last.floorsJson);
      final moved =
          before == null ||
          [for (var i = 0; i < 5; i++) (before[i] - zones[i]).abs()]
              .any((d) => d >= 3);
      final old = DateTime.now().difference(last.effectiveFrom).inDays >= 30;
      if (!moved || !old) return false;
    }
    return record(
      'running',
      zones,
      method: ZoneMethod.estimate,
      source: 'karvonen',
      // The first estimate covers every earlier workout.
      from: last == null ? DateTime.fromMillisecondsSinceEpoch(0) : null,
    );
  }
}
