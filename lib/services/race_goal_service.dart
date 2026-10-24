import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api/garmin_client.dart';
import '../db/database.dart';

/// Target races. Priority `a` is the season goal the plan builds toward.
class RaceGoalService {
  RaceGoalService(this._db);

  final AppDatabase _db;

  Future<List<RaceGoal>> getAll() {
    return (_db.select(_db.raceGoals)
          ..orderBy([(t) => OrderingTerm(expression: t.raceDate)]))
        .get();
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
          ..where((t) =>
              t.priority.equals('a') & t.raceDate.isBiggerOrEqualValue(now))
          ..orderBy([
            (t) => OrderingTerm(expression: t.raceDate, mode: OrderingMode.asc)
          ])
          ..limit(1))
        .getSingleOrNull();
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
    await _db.into(_db.raceGoals).insert(RaceGoalsCompanion.insert(
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
        ));
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
      final name = event['title'] as String? ??
          event['name'] as String? ??
          'Race ${date.year}-${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
      // Garmin reports race distance in km or m depending on the entry.
      final rawDistance = (event['distance'] as num?)?.toDouble() ?? 0.0;
      final distanceM = rawDistance > 0 && rawDistance < 1000
          ? rawDistance * 1000
          : rawDistance;
      final sport =
          _garminSportToFjelia(event['sportType'] as String? ?? '');

      final existingId = byGarminId[eventId];
      if (existingId != null) {
        await (_db.update(_db.raceGoals)
              ..where((t) => t.id.equals(existingId)))
            .write(RaceGoalsCompanion(
          name: Value(name),
          raceDate: Value(date),
          distanceM: Value(distanceM),
          primarySport: Value(sport),
          updatedAt: Value(DateTime.now()),
        ));
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
