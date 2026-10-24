import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
  });
  tearDown(() => db.close());

  Future<Set<String>> plannedSports({
    required String sport,
    required List<String> chosen,
    List<int> strengthDays = const [2, 4],
  }) async {
    await TrainingPlanService(db, FakeWorkoutGarmin()).generatePlan(
      athleteId: 'self',
      raceDate: DateTime.now().add(const Duration(days: 12 * 7)),
      sport: sport,
      raceDistanceM: 42195,
      daysPerWeek: 6,
      restDays: const [1],
      strengthDays: strengthDays,
      hoursPerWeek: 10,
      maxSessionsPerDay: 2,
      gadSports: chosen,
    );
    final rows = await db.select(db.trainingSessions).get();
    expect(rows, isNotEmpty);
    return rows.map((s) => s.sport).toSet();
  }

  test('yoga is only planned when it was chosen', () async {
    final without = await plannedSports(
      sport: 'running',
      chosen: ['running', 'cycling_road', 'swimming'],
    );
    expect(without, isNot(contains('yoga')));
    await db.delete(db.trainingSessions).go();
    final withYoga = await plannedSports(
      sport: 'running',
      chosen: ['running', 'yoga'],
    );
    // Chosen, the planner may use it again; the point is that it is the
    // athlete's decision, so the chosen sports are what appears.
    expect(withYoga.difference({'running', 'yoga', 'strength'}), isEmpty);
  });

  test('only chosen sports and the race sport appear', () async {
    final sports = await plannedSports(
      sport: 'running',
      chosen: ['running', 'hiking', 'swimming'],
    );
    expect(
      sports.difference({'running', 'hiking', 'swimming', 'strength'}),
      isEmpty,
    );
  });

  test('a gravel plan does not slip road rides in', () async {
    final sports = await plannedSports(
      sport: 'cycling_gravel',
      chosen: ['cycling_gravel'],
    );
    expect(sports, isNot(contains('cycling_road')));
    expect(sports, isNot(contains('yoga')));
  });

  test('without strength days there is no strength', () async {
    final sports = await plannedSports(
      sport: 'running',
      chosen: ['running'],
      strengthDays: const [],
    );
    expect(sports, {'running'});
  });
}
