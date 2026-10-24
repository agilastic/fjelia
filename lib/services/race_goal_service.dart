import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api/garmin_client.dart';
import '../db/database.dart';

/// Usual race distances in km.
const _standardRaceKm = [5.0, 10.0, 21.0975, 42.195, 50.0, 100.0];

/// A distance the user probably meant when [km] is a standard distance times
/// ten or divided by ten (422 for 42.2, 4.22 for 42.2), else null. Real races
/// of other lengths, such as 73 km, give null.
double? likelyRaceDistanceKm(double km) {
  bool near(double value, double target, double tolerance) =>
      (value - target).abs() <= target * tolerance;
  if (_standardRaceKm.any((s) => near(km, s, .03))) return null;
  for (final s in _standardRaceKm) {
    if (near(km / 10, s, .02) || near(km * 10, s, .02)) return s;
  }
  return null;
}

/// Target races. Priority `a` is the season goal the plan builds toward.
class RaceGoalService {
  RaceGoalService(this._db);

  final AppDatabase _db;

  Future<List<RaceGoal>> getAll() {
    return (_db.select(
      _db.raceGoals,
    )..orderBy([(t) => OrderingTerm(expression: t.raceDate)])).get();
  }

  Future<List<RaceGoal>> getUpcoming() {
    final now = DateTime.now();
    return (_db.select(_db.raceGoals)
          ..where((t) => t.raceDate.isBiggerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm(expression: t.raceDate)]))
        .get();
  }

  Future<RaceGoal?> getPrimaryGoal() {
    final now = DateTime.now();
    return (_db.select(_db.raceGoals)
          ..where(
            (t) =>
                t.priority.equals('a') & t.raceDate.isBiggerOrEqualValue(now),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.raceDate, mode: OrderingMode.asc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Fixes a marathon or half marathon saved with ten times its distance
  /// (422 km for 42.2 km), the only case recognisable from the name.
  /// Returns how many goals were changed.
  Future<int> repairImplausibleDistances() async {
    var fixed = 0;
    for (final g in await getAll()) {
      final name = g.name.toLowerCase();
      final half = name.contains('half') || name.contains('halb');
      final km = g.distanceM / 1000;
      final suggestion = likelyRaceDistanceKm(km);
      final target = half ? 21.0975 : 42.195;
      if (!name.contains('marathon') ||
          suggestion == null ||
          (suggestion - target).abs() > 0.01) {
        continue;
      }
      await (_db.update(_db.raceGoals)..where((t) => t.id.equals(g.id))).write(
        RaceGoalsCompanion(
          distanceM: Value(target * 1000),
          updatedAt: Value(DateTime.now()),
        ),
      );
      fixed++;
    }
    return fixed;
  }

  Future<void> create({
    required String name,
    required String primarySport,
    required double distanceM,
    required DateTime raceDate,
    required String priority,
    int? targetFinishSeconds,
    double? elevationM,
    String? garminEventId,
    String source = 'manual',
  }) async {
    await _db
        .into(_db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: const Uuid().v4(),
            athleteId: 'self',
            name: name,
            primarySport: primarySport,
            distanceM: distanceM,
            targetFinishSeconds: Value(targetFinishSeconds),
            raceDate: raceDate,
            priority: priority,
            elevationM: Value(elevationM),
            source: source,
            garminEventId: Value(garminEventId),
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Changes a goal. A null target time or elevation clears it.
  Future<void> update(
    String id, {
    required String name,
    required String primarySport,
    required double distanceM,
    required DateTime raceDate,
    required String priority,
    int? targetFinishSeconds,
    double? elevationM,
  }) async {
    await (_db.update(_db.raceGoals)..where((t) => t.id.equals(id))).write(
      RaceGoalsCompanion(
        name: Value(name),
        primarySport: Value(primarySport),
        distanceM: Value(distanceM),
        raceDate: Value(raceDate),
        priority: Value(priority),
        targetFinishSeconds: Value(targetFinishSeconds),
        elevationM: Value(elevationM),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updatePriority(String id, String priority) async {
    await (_db.update(_db.raceGoals)..where((t) => t.id.equals(id))).write(
      RaceGoalsCompanion(
        priority: Value(priority),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.raceGoals)..where((t) => t.id.equals(id))).go();
  }

  /// Imports race events from the Garmin calendar as B-priority goals and
  /// refreshes ones imported earlier.
  Future<void> syncFromGarmin(GarminClient garmin) async {
    final events = await garmin.getRaceEvents();
    final existing = await getAll();
    final byGarminId = <String, String>{
      for (final g in existing)
        if (g.garminEventId != null) g.garminEventId!: g.id,
    };

    for (final event in events) {
      final eventId = (event['id'] ?? event['eventId'])?.toString();
      final date = DateTime.tryParse(event['date'] as String? ?? '');
      if (eventId == null || date == null) continue;
      final name =
          event['title'] as String? ??
          event['name'] as String? ??
          'Race ${date.year}-${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
      // Garmin reports race distance in km or m depending on the entry.
      final rawDistance = (event['distance'] as num?)?.toDouble() ?? 0.0;
      final distanceM = rawDistance > 0 && rawDistance < 1000
          ? rawDistance * 1000
          : rawDistance;
      final sport = _garminSportToFjelia(event['sportType'] as String? ?? '');

      final existingId = byGarminId[eventId];
      if (existingId != null) {
        await (_db.update(
          _db.raceGoals,
        )..where((t) => t.id.equals(existingId))).write(
          RaceGoalsCompanion(
            name: Value(name),
            raceDate: Value(date),
            distanceM: Value(distanceM),
            primarySport: Value(sport),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await create(
          name: name,
          primarySport: sport,
          distanceM: distanceM,
          raceDate: date,
          priority: 'b',
          garminEventId: eventId,
          source: 'garmin',
        );
      }
    }
  }

  String _garminSportToFjelia(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('trail')) return 'trail_running';
    if (s.contains('run')) return 'running';
    if (s.contains('mtb') || s.contains('mountain')) return 'cycling_mtb';
    if (s.contains('gravel')) return 'cycling_gravel';
    if (s.contains('cycl') || s.contains('bike')) return 'cycling_road';
    if (s.contains('swim')) return 'swimming';
    if (s.contains('tri')) return 'triathlon';
    if (s.contains('row')) return 'indoor_rowing';
    return 'running';
  }
}
