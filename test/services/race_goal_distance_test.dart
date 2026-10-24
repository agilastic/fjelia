import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/race_goal_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('likelyRaceDistanceKm', () {
    test('a standard distance times ten or divided by ten is questioned', () {
      expect(likelyRaceDistanceKm(422), 42.195);
      expect(likelyRaceDistanceKm(4.22), 42.195);
      expect(likelyRaceDistanceKm(210.9), 21.0975);
      expect(likelyRaceDistanceKm(100 * 10), 100);
    });

    test('real distances are left alone', () {
      for (final km in [
        5.0,
        10.0,
        21.1,
        42.2,
        42.195,
        50.0,
        73.0,
        100.0,
        160.9,
      ]) {
        expect(likelyRaceDistanceKm(km), isNull, reason: '$km km');
      }
    });
  });

  group('repairImplausibleDistances', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> goal(String id, String name, double meters) => db
        .into(db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: id,
            athleteId: 'self',
            name: name,
            primarySport: 'running',
            distanceM: meters,
            raceDate: DateTime(2027, 4, 11),
            priority: 'a',
            source: 'manual',
            createdAt: DateTime(2026, 10, 19),
          ),
        );

    Future<double> distance(String id) async => (await (db.select(
      db.raceGoals,
    )..where((t) => t.id.equals(id))).getSingle()).distanceM;

    test(
      'a marathon of 422 km becomes 42.195 km, nothing else changes',
      () async {
        await goal('m', 'marathon Hannover', 422000);
        await goal('h', 'Berlin Halbmarathon', 210900);
        await goal('ok', 'Hannover Marathon', 42195);
        await goal('ultra', 'Allgäu Panorama Marathon', 73000);
        await goal('other', 'Race of 422 km', 422000);
        expect(await RaceGoalService(db).repairImplausibleDistances(), 2);
        expect(await distance('m'), 42195);
        expect(await distance('h'), 21097.5);
        expect(await distance('ok'), 42195);
        expect(await distance('ultra'), 73000);
        expect(await distance('other'), 422000);
        expect(await RaceGoalService(db).repairImplausibleDistances(), 0);
      },
    );
  });
}
